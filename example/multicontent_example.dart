import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:multicontent/multicontent.dart';
import 'package:multicontent/src/streamsplitter.dart';

List<ByteMultiContentPart> generateTestParts() {
  final rng = Random();

  final partsCount = rng.nextInt(10) + 5;
  final totalContentLength = rng.nextInt(100 * 1000) + 60 * 1000;

  var filled = 0;
  final parts = <ByteMultiContentPart>[];

  for (var _ = 0; _ < partsCount; _++) {
    final remainingLength = totalContentLength - filled;
    late final Uint8List byteArray;
    if (remainingLength < 1000) {
      byteArray = Uint8List(remainingLength);
      break;
    } else {
      final threshold = remainingLength ~/ partsCount;
      final length =
          min(threshold, 100) + rng.nextInt(remainingLength - threshold);
      byteArray = Uint8List(length);
    }
    filled += byteArray.length;

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

    parts.add(ByteMultiContentPart(bytes: byteArray));
  }

  return parts;
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

Future<void> testByteMultiContents() async {
  final parts = generateTestParts();
  final multiContent = MultiContent(parts);

  final totalLength = await multiContent.getLength();
  print("total Length: $totalLength");

  final stream = multiContent.getStream();
  final bytes = (await stream.toList()).expand((_) => _).toList();

  var i = 0;
  for (var part in parts) {
    final startList = bytes.sublist(i, i + 10);

    i += await part.length();
    final endList = bytes.sublist(i - 10, i);

    final areChunksEqualStart =
        areListsEqual(startList, part.bytes.sublist(0, 10));
    final areChunksEqualEnd = areListsEqual(
        endList, part.bytes.sublist(part.bytes.length - 10, part.bytes.length));
    print(
        "chunk $part check start: $areChunksEqualStart end: $areChunksEqualEnd");
  }

  final contentType = await multiContent.getContentType();
  print("content type: $contentType");
  final inputStream = ByteMultiContentPart(bytes: bytes).stream();

  final splitter = MultiContentSplitter(contentType, inputStream);
  var index = 0;
  void onPart(ByteMultiContentPart part) {
    final result = areListsEqual(part.bytes, parts[index].bytes);
    print("index result $index $result");
    index += 1;
  }

  await for (var part in splitter.split()) {
    onPart(part);
  }
}

String fileBaseName(String path) {
  if (path.contains('\\')) {
    return path.split('\\').last;
  } else {
    return path.split('/').last;
  }
}

Future<void> testFiles() async {
  final dir = Directory("./test-files");
  final files = List<File>.from(await dir.list().toList());

  final parts = files
      .map((file) => FileMultiContentPart(
          file: file, additionalInfo: fileBaseName(file.path)))
      .toList();

  final multiContent = MultiContent(parts);

  final contentType = await multiContent.getContentType();
  final stream = multiContent.getStream();
  final splitter = MultiContentSplitter(contentType, stream);

  // var i = 0;
  await for (final part in splitter.split()) {
    await File("./output/${part.additionalInfo}").writeAsBytes(part.bytes);
  }
}

Future<void> testTestFiles() async {
  final dir = Directory("./test-files");
  final files = List<File>.from(await dir.list().toList());

  final parts = files
      .map((file) => FileMultiContentPart(
          file: file, additionalInfo: fileBaseName(file.path)))
      .toList();

  final multiContent = MultiContent(parts);

  final contentType = await multiContent.getContentType();
  final stream = multiContent.getStream();
  final splitter = MultiContentSplitter(contentType, stream);
  await splitter.splitAndWriteToFiles(Directory("./output")).toList();
}

void main() {
  // testByteMultiContents();
  Directory("./output").deleteSync(recursive: true);
  testTestFiles();
}
