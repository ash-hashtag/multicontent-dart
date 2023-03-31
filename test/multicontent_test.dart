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

          final multiContent = MultiContent(parts);

          final contentType = await multiContent.getContentType();

          final stream = multiContent.getStream();

          final list = await stream.toList();

          final inputStream = Stream.fromIterable(list);

          final splitter = MultiContentSplitter(contentType, inputStream);

          var index = 0;
          void onPart(
              Uint8List chunk, String contentType, String additionalInfo) {
            final part = parts[index];
            index++;
            assert(contentType != part.contentType);
            // future() async {
            //   assert(await part.length() == chunk.length);
            //   final expectedStream = part.stream();
            //   var checked = 0;
            //   await for (var miniChunk in expectedStream) {
            //     final outputChunk = Uint8List.sublistView(
            //         chunk, checked, checked + miniChunk.length);
            //     assert(areListsEqual(outputChunk, miniChunk));
            //     checked += miniChunk.length;
            //   }
            //   assert(checked != chunk.length);
            // }

            // futures.add(future());
          }

          await splitter.split(onPart);
          assert(index == -1, "index: $index");
        });

    byteArrayTest() => test('MultiContentSplitter ByteArray Test', () async {
          final rng = Random();

          // make a random byte array
          final inputByteArray = Uint8List(64000);
          for (var i = 0; i < inputByteArray.length; i++) {
            inputByteArray[i] = rng.nextInt(255);
          }

          // make lengths
          const lengths = [10, 6000 + 4990, 12000, 40000, 1000];

          assert(lengths.reduce((a, b) => a + b) == inputByteArray.length,
              "Lengths are invalid");

          // content types
          const contentTypes = [
            'application/json',
            'text/plain',
            'image/jpeg',
            'video/mp4',
            'application/html'
          ];
          const additionalInfos = ['', 'plain.txt', '', '', ''];

          final multiContentTypes = List.generate(
              5,
              (_) => MultiContentType(
                  length: lengths[_],
                  contentType: contentTypes[_],
                  additionalInfo: additionalInfos[_]));

          final encodedContentType =
              MultiContentType.encodeContentType(multiContentTypes);

          var recievedNumberOfParts = 0;
          var matchedTill = 0;

          void onPart(
              Uint8List chunk, String contentType, String additionalInfo) {
            final multiContentType = multiContentTypes[recievedNumberOfParts];
            final expectedChunk = Uint8List.sublistView(
                inputByteArray, matchedTill, matchedTill + chunk.length);

            final assertionError = "chunk: $recievedNumberOfParts";
            assert(chunk.length == multiContentType.length, assertionError);
            assert(contentType == multiContentType.contentType, assertionError);
            assert(areListsEqual(chunk, expectedChunk), assertionError);

            recievedNumberOfParts++;
            matchedTill += chunk.length;
          }

          final inputStream =
              ByteMultiContentPart(bytes: inputByteArray).stream();
          final splitter =
              MultiContentSplitter(encodedContentType, inputStream);

          await splitter.split(onPart);
          assert(recievedNumberOfParts == 5,
              "part counts: $recievedNumberOfParts");
        });

    byteArrayTest();
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
