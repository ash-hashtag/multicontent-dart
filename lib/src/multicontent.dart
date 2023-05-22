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

    final contentTypes = <MultiContentType>[];

    for (var i = 0; i < parts.length; i++) {
      final length = lengths[i];
      final part = parts[i];
      contentTypes.add(MultiContentType(
          length: length,
          contentType: part.contentType,
          additionalInfo: part.additionalInfo));
    }

    return encodeContentType(contentTypes);
  }
}

String encodeContentType(List<MultiContentType> contentTypes) {
  var contentType = "multicontent ";

  contentType += contentTypes.map((e) => e.encode()).join('|');

  return contentType;
}

String decodeSpecialChars(String s) =>
    s.replaceAll(r'\,', ',').replaceAll(r'\|', '|');

String encodeSpecialChars(String s) =>
    s.replaceAll(',', r'\,').replaceAll('|', r'\|');

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
    final encodedContentType = encodeSpecialChars(contentType);

    final s = [
      length,
      encodedContentType,
      if (additionalInfo.isNotEmpty) encodeSpecialChars(additionalInfo)
    ].join(',');

    return s;
  }

  @override
  String toString() =>
      "{ length: $length, contentType: $contentType, additionalInfo: $additionalInfo }";
}
