import 'dart:async';
import 'package:multicontent/src/multicontent_part.dart';

class MultiContent {
  final List<MultiContentPart> parts;

  const MultiContent(this.parts);

  Stream<List<int>> getStream() async* {
    for (final part in parts) {
      yield* part.stream();
    }
  }

  Future<List<int>> getEachLength() =>
      Future.wait(parts.map((e) => e.length()));

  Future<int> getLength() =>
      getEachLength().then((value) => value.reduce((a, b) => a + b));

  Future<String> getContentType() async {
    final lengths = await getEachLength();
    
    // var index = 0;

    final contentTypes = <MultiContentType>[];

    for (var i = 0; i < parts.length; i++) {
      final length = lengths[i];
      final part = parts[i];
      contentTypes.add(MultiContentType(length: length, contentType: part.contentType, additionalInfo: part.additionalInfo));
      // contentType +=
      //     '${MultiContentType(index: index, contentType: contentType, additionalInfo: parts[i].additionalInfo()).encode()}|';
      // index += length;
    }

    return MultiContentType.encodeContentType(contentTypes);
  }

  static void fromStream(Stream<List<int>> stream, String contentType, void Function(Stream<List<int>>, int, String) onPart) {
    final multiContentTypes = MultiContentType.parseContentType(contentType);

  }

}

class MultiContentType {
  final int length;
  final String contentType;
  final String additionalInfo;

  const MultiContentType({
    required this.length,
    required this.contentType,
    required this.additionalInfo,
  });

  static List<MultiContentType> parseContentType(String multiContentType) {
    String decodeSpecialChars(String s) =>
        s.replaceAll(r'\,', ',').replaceAll(r'\|', '|');

    final partContentTypes = <MultiContentType>[];

    if (multiContentType.startsWith("multicontent ")) {
      final contentTypesContentType = multiContentType.substring(13);
      final parts = contentTypesContentType.split(RegExp(r"(?<!\\)\|"));

      for (final e in parts) {
        final commaSeperatedParts = e.split(RegExp(r"(?<!\\),"));
        if (commaSeperatedParts.length >= 2) {
          final length = int.tryParse(commaSeperatedParts.first);
          if (length == null) {
            throw UnsupportedError("Invalid Format $multiContentType");
          }

          final contentType = decodeSpecialChars(commaSeperatedParts[1]);
          final additionalInfo =
              decodeSpecialChars(commaSeperatedParts.sublist(2).join());
          partContentTypes.add(MultiContentType(
              length: length,
              contentType: contentType,
              additionalInfo: additionalInfo));
        }
      }
    } else {
      throw UnsupportedError("Unsupported Formatt $multiContentType");
    }
    return partContentTypes;
  }

  String encode() {
    String encodeSpecialChars(String s) =>
        s.replaceAll(',', r'\,').replaceAll('|', r'\|');

    final encodedContentType = encodeSpecialChars(contentType);

    final s = [
      length,
      encodedContentType,
      if (additionalInfo.isNotEmpty) encodeSpecialChars(additionalInfo)
    ].join(',');

    return s;
  }

  @override
  String toString() => "{ length: $length, contentType: $contentType, additionalInfo: $additionalInfo }";

  static String encodeContentType(List<MultiContentType> contentTypes) {
    var contentType = "multicontent ";

    contentType += contentTypes.map((e) => e.encode()).join('|');

    return contentType;
  }

}

/*
I'd like to make a simple and very compressed string encoder and decoder, that takes a list of class Foo {int num, string s, string f} and converts them to a very compressed string, which should also be able to parse them back.

*/