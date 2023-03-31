import 'dart:io';
import 'dart:math';

const octetStreamContentType = "application/octet-stream";

abstract class MultiContentPart {
  final String contentType, additionalInfo;

  const MultiContentPart(
      {required this.contentType, required this.additionalInfo});

  Future<int> length();

  Stream<List<int>> stream();
}

class FileMultiContentPart extends MultiContentPart {
  final File file;

  const FileMultiContentPart({
    required this.file,
    String contentType = octetStreamContentType,
    String additionalInfo = '',
  }) : super(contentType: contentType, additionalInfo: additionalInfo);

  @override
  Stream<List<int>> stream() => file.openRead();

  @override
  Future<int> length() => file.length();
}

class ByteMultiContentPart extends MultiContentPart {
  final List<int> bytes;

  const ByteMultiContentPart({
    required this.bytes,
    String contentType = octetStreamContentType,
    String additionalInfo = '',
  }) : super(contentType: contentType, additionalInfo: additionalInfo);

  @override
  Stream<List<int>> stream() async* {
    const chunkSize = 1024;
    if (bytes.length < chunkSize) {
      yield bytes;
    } else {
      for (var i = 0; i < bytes.length; i += chunkSize) {
        yield bytes.sublist(i, min(i + chunkSize, bytes.length));
      }
    }
  }

  @override
  Future<int> length() async => bytes.length;
}

class StreamMultiContentPart extends MultiContentPart {
  final Stream<List<int>> innerStream;
  final int streamLength;

  const StreamMultiContentPart({
    required this.innerStream,
    String contentType = octetStreamContentType,
    required this.streamLength,
    String additionalInfo = '',
  }) : super(contentType: contentType, additionalInfo: additionalInfo);

  @override
  Stream<List<int>> stream() => innerStream;

  @override
  Future<int> length() async => streamLength;
}
