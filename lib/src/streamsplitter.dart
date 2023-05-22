import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:multicontent/multicontent.dart';

class MultiContentSplitter {
  final String contentType;
  final Stream<List<int>> stream;

  const MultiContentSplitter(this.contentType, this.stream);

  Stream<ByteMultiContentPart> split() async* {
    final contentTypes = MultiContentType.parseContentType(contentType);
    if (contentTypes.isEmpty) {
      throw RangeError("Content Types is Empty");
    }

    var index = 0;
    var buffer = Uint8List(contentTypes.first.length);
    var bufferFilled = 0;

    await for (final chunk in stream) {
      var chunkRead = 0;
      while (chunkRead < chunk.length) {
        final bufferRemainingSpace = buffer.length - bufferFilled;
        final chunkRemainingToRead = chunk.length - chunkRead;
        if (bufferRemainingSpace > chunkRemainingToRead) {
          final requiredChunk = chunk.sublist(chunkRead);
          buffer.setAll(bufferFilled, requiredChunk);
          bufferFilled += chunkRemainingToRead;
          break;
        } else {
          final requiredChunk =
              chunk.sublist(chunkRead, chunkRead + bufferRemainingSpace);
          buffer.setAll(bufferFilled, requiredChunk);
          bufferFilled += requiredChunk.length;
          {
            final contentType = contentTypes[index].contentType;
            final additionalInfo = contentTypes[index].additionalInfo;
            final part = ByteMultiContentPart(
                bytes: buffer,
                contentType: contentType,
                additionalInfo: additionalInfo);
            // onPart(part);
            yield part;

            index += 1;
            if (index >= contentTypes.length) {
              return;
            }

            buffer = Uint8List(contentTypes[index].length);
            bufferFilled = 0;
          }
          chunkRead += bufferRemainingSpace;
        }
      }
    }

    if (index < contentType.length) {
      {
        if (buffer.isEmpty || bufferFilled == 0) {
          return;
        }
        final contentType = contentTypes[index].contentType;
        final additionalInfo = contentTypes[index].additionalInfo;
        final part = ByteMultiContentPart(
            bytes: buffer,
            contentType: contentType,
            additionalInfo: additionalInfo);
        yield part;

        index += 1;
        if (index >= contentTypes.length) {
          return;
        }

        buffer = Uint8List(contentTypes[index].length);
        bufferFilled = 0;
      }
    }
  }

  Stream<FileMultiContentPart> splitAndWriteToFiles(
      Directory directory) async* {
    final contentTypes = MultiContentType.parseContentType(contentType);
    if (contentTypes.isEmpty) {
      throw RangeError("Content Types is Empty");
    }

    var index = 0;
    var buffer = Uint8List(contentTypes.first.length);
    var fileLength = contentTypes.first.length;
    var file = File('${directory.path}/${contentTypes.first.additionalInfo}');
    await file.create(recursive: true);
    var bufferFilled = 0;
    var sink = file.openWrite();

    await for (final chunk in stream) {
      var chunkRead = 0;
      while (chunkRead < chunk.length) {
        final bufferRemainingSpace = fileLength - bufferFilled;
        final chunkRemainingToRead = chunk.length - chunkRead;
        if (bufferRemainingSpace > chunkRemainingToRead) {
          final requiredChunk = chunk.sublist(chunkRead);
          // buffer.setAll(bufferFilled, requiredChunk);
          sink.add(requiredChunk);
          bufferFilled += chunkRemainingToRead;
          break;
        } else {
          final requiredChunk =
              chunk.sublist(chunkRead, chunkRead + bufferRemainingSpace);
          // buffer.setAll(bufferFilled, requiredChunk);
          sink.add(requiredChunk);
          bufferFilled += requiredChunk.length;
          {
            final contentType = contentTypes[index].contentType;
            final additionalInfo = contentTypes[index].additionalInfo;
            // final part = ByteMultiContentPart(
            //     bytes: buffer,
            //     contentType: contentType,
            //     additionalInfo: additionalInfo);
            await sink.flush();
            await sink.close();
            yield FileMultiContentPart(
                file: file,
                additionalInfo: additionalInfo,
                contentType: contentType);
            // onPart(part);
            // yield part;

            index += 1;
            if (index >= contentTypes.length) {
              return;
            }

            // buffer = Uint8List(contentTypes[index].length);
            file =
                File("${directory.path}/${contentTypes[index].additionalInfo}");
            fileLength = contentTypes[index].length;
            sink = file.openWrite();
            bufferFilled = 0;
          }
          chunkRead += bufferRemainingSpace;
        }
      }
    }

    if (index < contentType.length) {
      {
        if (buffer.isEmpty || bufferFilled == 0) {
          return;
        }
        final contentType = contentTypes[index].contentType;
        final additionalInfo = contentTypes[index].additionalInfo;
        // final part = ByteMultiContentPart(
        //     bytes: buffer,
        //     contentType: contentType,
        //     additionalInfo: additionalInfo);
        yield FileMultiContentPart(
            file: file,
            additionalInfo: additionalInfo,
            contentType: contentType);
        // yield part;

        index += 1;
        if (index >= contentTypes.length) {
          return;
        }

        file = File("${directory.path}/${contentTypes[index].additionalInfo}");
        fileLength = contentTypes[index].length;
        // buffer = Uint8List(contentTypes[index].length);
        sink = file.openWrite();
        bufferFilled = 0;
      }
    }
  }
}
