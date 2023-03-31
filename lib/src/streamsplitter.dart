import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:multicontent/multicontent.dart';

class MultiContentSplitter {
  final String contentType;
  final Stream<List<int>> stream;

  const MultiContentSplitter(this.contentType, this.stream);

  void split(
      void Function(Uint8List chunk, String contentType, String additionalInfo)
          onPart) async {
    final contentTypes = MultiContentType.parseContentType(contentType);
    if (contentTypes.isEmpty) {
      throw RangeError("Content Types is Empty");
    }

    var index = 0;

    var currentChunkLength = contentTypes.first.length;
    var buffer = Uint8Buffer(currentChunkLength);

    bool next() {
      onPart(buffer.buffer, contentTypes[index].contentType,
          contentTypes[index].additionalInfo);
      if (index + 1 >= contentTypes.length) {
        return false;
      }
      index++;
      buffer.reset(contentTypes[index].length);
      return true;
    }

    await for (final chunk in stream) {
      final len = chunk.length;
      var chunkRead = 0;
      while (true) {
        final remainingSpace = buffer.remainingSpace;
        if (remainingSpace < len) {
          final end = min(len, remainingSpace);
          buffer.push(chunk.sublist(chunkRead, end));
          if (!next()) {
            return;
          }
          chunkRead += remainingSpace;
        } else {
          break;
        }
      }
    }
  }
}

class Uint8Buffer {
  Uint8List _buffer;
  var _filled = 0;

  Uint8Buffer(int capacity) : _buffer = Uint8List(capacity);

  void push(Iterable<int> iterable) {
    _buffer.setAll(_filled, iterable);
  }

  void reset(int newLength) {
    _filled = 0;
    if (newLength < capacity) {
      _buffer = Uint8List.sublistView(_buffer, 0, newLength);
    } else if (newLength > capacity) {
      _buffer = Uint8List(newLength);
    }
  }

  Uint8List get buffer => Uint8List.fromList(_buffer);

  int get length => _filled;

  int get capacity => _buffer.length;

  int get remainingSpace => capacity - length;
}
