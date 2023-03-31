import 'dart:async';
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

    // bool next() {
    //   final contentType = contentTypes[index].contentType;
    //   final additionalInfo = contentTypes[index].additionalInfo;
    //   final part = ByteMultiContentPart(
    //       bytes: buffer,
    //       contentType: contentType,
    //       additionalInfo: additionalInfo);
    //   // onPart(part);

    //   index += 1;
    //   if (index >= contentTypes.length) {
    //     return false;
    //   }

    //   buffer = Uint8List(contentTypes[index].length);
    //   bufferFilled = 0;

    //   return true;
    // }

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
          // if (!next()) {
          //   return;
          // }
          chunkRead += bufferRemainingSpace;
        }
      }
    }

    if (index < contentType.length) {
      // next();
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
        // onPart(part);
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
}

// class Uint8Buffer {
//   Uint8List _buffer;
//   var _filled = 0;

//   Uint8Buffer(int capacity) : _buffer = Uint8List(capacity);

//   void push(Iterable<int> iterable) {
//     _buffer.setAll(_filled, iterable);
//   }

//   void reset(int newLength) {
//     _filled = 0;
//     if (newLength < capacity) {
//       _buffer = Uint8List.sublistView(_buffer, 0, newLength);
//     } else if (newLength > capacity) {
//       _buffer = Uint8List(newLength);
//     }
//   }

//   Uint8List get buffer => _buffer;

//   Uint8List get copyBuffer => Uint8List.fromList(_buffer);

//   int get length => _filled;

//   int get capacity => _buffer.length;

//   int get remainingSpace => capacity - length;
// }
