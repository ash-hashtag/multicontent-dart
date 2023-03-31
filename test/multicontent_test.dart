import 'package:multicontent/multicontent.dart';
import 'package:test/test.dart';

void main() {
  group('MultiContentType tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('MultiContentType Parsing Test', () {
      final contentTypes = MultiContentType.parseContentType(
          "multicontent 100,application/octet-stream|100,text/plain,plain.txt");

      final expectedContentTypes = [
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
      final contentTypes = [
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

      final expectedContentType =
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
