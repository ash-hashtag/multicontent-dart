import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:multicontent/multicontent.dart';
import 'package:multicontent/src/streamsplitter.dart';
import 'package:test/test.dart';

void multiContentTypeTests() {
  group('MultiContentType tests', () {
    test('MultiContentType Parsing Test', () {
      final contentTypes = MultiContentType.parseContentType(
          "multicontent 100,application/octet-stream|100,text/plain,plain.txt");

      const expectedContentTypes = [
        MultiContentType(
            length: 100,
            contentType: "application/octet-stream",
            additionalInfo: ''),
        MultiContentType(
            length: 100,
            contentType: "text/plain",
            additionalInfo: 'plain.txt'),
      ];

      assert(expectedContentTypes.toString() == contentTypes.toString());
    });

    test('MultiContentType Encoding Test', () {
      const contentTypes = [
        MultiContentType(
            length: 100,
            contentType: "application/octet-stream",
            additionalInfo: ''),
        MultiContentType(
            length: 100,
            contentType: "text/plain",
            additionalInfo: 'plain.txt'),
        MultiContentType(
            length: 100, contentType: "image/jpeg", additionalInfo: ''),
        MultiContentType(
            length: 100, contentType: "text/toml", additionalInfo: ''),
        MultiContentType(
            length: 100,
            contentType: "application/octet-stream",
            additionalInfo: ''),
      ];
      final contentType = MultiContentType.encodeContentType(contentTypes);

      const expectedContentType =
          "multicontent 100,application/octet-stream|100,text/plain,plain.txt|100,image/jpeg|100,text/toml|100,application/octet-stream";

      printOnFailure(
          "$contentTypes\n content type: $contentType\n expected content type: $expectedContentType\n");
      assert(contentType == expectedContentType);
    });
  });

  test('MultiContentType Both Encode And Decode Test', () {
    final contentTypes = [
      MultiContentType(
          length: 100,
          contentType: "application/octet-stream",
          additionalInfo: ''),
      MultiContentType(
          length: 100, contentType: "text/plain", additionalInfo: 'plain.txt'),
      MultiContentType(
          length: 100, contentType: "image/jpeg", additionalInfo: ''),
      MultiContentType(
          length: 100, contentType: "text/toml", additionalInfo: ''),
      MultiContentType(
          length: 100,
          contentType: "application/octet-stream",
          additionalInfo: ''),
    ];

    var encodedContentType = MultiContentType.encodeContentType(contentTypes);

    var decodedContentTypes =
        MultiContentType.parseContentType(encodedContentType);

    assert(contentTypes.toString() == decodedContentTypes.toString());

    var newMultiContentType = MultiContentType(
        length: 200, contentType: encodedContentType, additionalInfo: '');

    contentTypes.add(newMultiContentType);

    encodedContentType = MultiContentType.encodeContentType(contentTypes);
    decodedContentTypes = MultiContentType.parseContentType(encodedContentType);

    assert(contentTypes.toString() == decodedContentTypes.toString());

    newMultiContentType = MultiContentType(
        length: 200, contentType: encodedContentType, additionalInfo: '');

    contentTypes.insert(2, newMultiContentType);

    encodedContentType = MultiContentType.encodeContentType(contentTypes);
    decodedContentTypes = MultiContentType.parseContentType(encodedContentType);

    assert(contentTypes.toString() == decodedContentTypes.toString());
  });
}

List<ByteMultiContentPart> generateTestParts() {
  final rng = Random();

  final partsCount = rng.nextInt(10) + 5;
  final parts = List.generate(partsCount, (_) {
    final byteArray = Uint8List(rng.nextInt(100 * 1000) + 100 * 1000);

    if (byteArray.length < 20) {
      for (var i = 0; i < byteArray.length; i++) {
        byteArray[i] = rng.nextInt(255);
      }
    } else {
      for (var i = 0; i < 10; i++) {
        byteArray[i] = rng.nextInt(255);
      }
      for (var i = byteArray.length - 10; i < byteArray.length; i++) {
        byteArray[i] = rng.nextInt(255);
      }
    }

    return ByteMultiContentPart(bytes: byteArray);
  });

  // final totalContentLength = rng.nextInt(100 * 1000) + 60 * 1000;

  // var filled = 0;
  // final parts = <ByteMultiContentPart>[];
  // for (var _ = 0; _ < partsCount; _++) {
  //   final remainingLength = totalContentLength - filled;
  //   late final Uint8List byteArray;
  //   if (remainingLength < 1000) {
  //     byteArray = Uint8List(remainingLength);
  //     break;
  //   } else {
  //     final threshold = remainingLength ~/ partsCount;
  //     final length =
  //         min(threshold, 100) + rng.nextInt(remainingLength - threshold);
  //     byteArray = Uint8List(length);
  //   }
  //   filled += byteArray.length;

  //   if (byteArray.length < 20) {
  //     for (var i = 0; i < byteArray.length; i++) {
  //       byteArray[i] = rng.nextInt(255);
  //     }
  //   } else {
  //     for (var i = 0; i < 10; i++) {
  //       byteArray[i] = rng.nextInt(255);
  //     }
  //     for (var i = byteArray.length - 10; i < byteArray.length; i++) {
  //       byteArray[i] = rng.nextInt(255);
  //     }
  //   }

  //   parts.add(ByteMultiContentPart(bytes: byteArray));
  // }

  return parts;
}

void multiContentSplitterTests() {
  group('MultiContentSplitter tests', () {
    filesTest() => test('MultiContentSplitter Files Test', () async {
          final dir = Directory("./test-files");
          final files = dir.listSync();
          final parts = <MultiContentPart>[];
          for (var fileEntry in files) {
            final file = File(fileEntry.path);
            final fileName = file.path.split(RegExp(r'\/|\\')).last;
            final part =
                FileMultiContentPart(file: file, additionalInfo: fileName);
            parts.add(part);
          }
          {
            final jsonString = jsonEncode({"value": 10});
            final bytes = jsonString.codeUnits;
            final part = ByteMultiContentPart(
                bytes: bytes,
                contentType: "application/json",
                additionalInfo: "hello.json");
            parts.add(part);
          }

          {
            final multiContent = MultiContent(List.from(parts));
            final contentType = await multiContent.getContentType();
            final stream = multiContent.getStream();

            // final contentLength = await multiContent.getLength();
            // final streamPart = StreamMultiContentPart(
            //     innerStream: stream,
            //     contentType: contentType,
            //     streamLength: contentLength);

            // parts.add(streamPart);
            final bytes = (await stream.toList()).expand((_) => _).toList();
            final part =
                ByteMultiContentPart(bytes: bytes, contentType: contentType);
            parts.add(part);
          }
          // final list = await stream.toList();

          final multiContent = MultiContent(parts);

          final contentType = await multiContent.getContentType();

          final stream = multiContent.getStream();

          // final inputStream = Stream.fromIterable(list);

          final splitter = MultiContentSplitter(contentType, stream);

          var index = 0;
          var readCount = 0;
          final futures = <Future>[];
          void onPart(ByteMultiContentPart part) {
            final expectedPart = parts[index];
            index++;
            assert(expectedPart.contentType == part.contentType);
            future() async {
              assert(await part.length() == part.bytes.length);
              final expectedStream = expectedPart.stream();
              var checked = 0;
              await for (var miniChunk in expectedStream) {
                final outputChunk =
                    part.bytes.sublist(checked, checked + miniChunk.length);
                assert(areListsEqual(outputChunk, miniChunk));
                checked += miniChunk.length;
              }
              assert(checked == part.bytes.length);
              readCount += 1;
            }

            futures.add(future());
          }

          await for (var part in splitter.split()) {
            onPart(part);
          }
          await Future.wait(futures);

          assert(index == parts.length, "index: $index");
          assert(readCount == parts.length,
              "readCount: $readCount != ${parts.length}");
        });

    byteArrayTest() => test('MultiContentSplitter ByteArray Test', () async {
          // final rng = Random();

          final parts = generateTestParts();
          final multiContent = MultiContent(parts);

          final stream = multiContent.getStream();
          final inputByteArray =
              (await stream.toList()).expand((_) => _).toList();

          // // make a random byte array
          // final inputByteArray = Uint8List(64000);
          // for (var i = 0; i < inputByteArray.length; i++) {
          //   inputByteArray[i] = rng.nextInt(255);
          // }

          // // make lengths
          // const lengths = [10, 6000 + 4990, 12000, 40000, 1000];

          // assert(lengths.reduce((a, b) => a + b) == inputByteArray.length,
          //     "Lengths are invalid");

          // // content types
          // const contentTypes = [
          //   'application/json',
          //   'text/plain',
          //   'image/jpeg',
          //   'video/mp4',
          //   'application/html'
          // ];
          // const additionalInfos = ['', 'plain.txt', '', '', ''];

          // final multiContentTypes = List.generate(
          //     5,
          //     (_) => MultiContentType(
          //         length: lengths[_],
          //         contentType: contentTypes[_],
          //         additionalInfo: additionalInfos[_]));
          final encodedContentType = await multiContent.getContentType();
          // MultiContentType.encodeContentType(multiContentTypes);

          var recievedNumberOfParts = 0;

          void onPart(ByteMultiContentPart part) {
            final expectedContentType =
                parts[recievedNumberOfParts].contentType;
            final chunk = part.bytes;
            // final expectedChunk = Uint8List.sublistView(
            // inputByteArray, matchedTill, matchedTill + chunk.length);
            final expectedChunk = parts[recievedNumberOfParts].bytes;

            final contentType = part.contentType;
            final assertionError = "chunk: $recievedNumberOfParts";
            assert(contentType == expectedContentType, assertionError);
            assert(areListsEqual(chunk, expectedChunk), assertionError);

            recievedNumberOfParts++;
          }

          final inputStream =
              ByteMultiContentPart(bytes: inputByteArray).stream();
          final splitter =
              MultiContentSplitter(encodedContentType, inputStream);

          await for (var part in splitter.split()) {
            onPart(part);
          }
          assert(recievedNumberOfParts == parts.length,
              "part counts: $recievedNumberOfParts");
        });

    streamTest() => test('StreamMultiContentPart test', () async {
          final parts = List<MultiContentPart>.from(generateTestParts());
          {
            final multiContent = MultiContent(parts.toList());
            final contentType = await multiContent.getContentType();
            final contentLength = await multiContent.getLength();

            final streamPart = StreamMultiContentPart(
                innerStream: multiContent.getStream(),
                streamLength: contentLength,
                contentType: contentType);
            parts.add(streamPart);
          }

          final multiContent = MultiContent(parts);
          final contentType = await multiContent.getContentType();
          final contentLength = await multiContent.getLength();

          final stream = multiContent.getStream();
          await for (var _ in stream) {}
        });

    // byteArrayTest();
    filesTest();
    // streamTest();
  });
}

bool areListsEqual<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}

void main() {
  multiContentSplitterTests();
}
