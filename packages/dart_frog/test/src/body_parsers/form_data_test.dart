// ignoring for testing purposes
// ignore_for_file: prefer_const_constructors
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/src/body_parsers/form_data.dart';
import 'package:test/test.dart';

void main() {
  group('parseFormData', () {
    test('throws StateError when content-type header is missing', () async {
      const message = '''
Body could not be parsed as form data due to an invalid MIME type.
Expected MIME type: "application/x-www-form-urlencoded" OR "multipart/form-data"
Actual MIME type: ""
''';
      expect(
        parseFormData(
          headers: {},
          body: () async => '',
          bytes: () async* {},
        ),
        throwsA(isA<StateError>().having((e) => e.message, 'message', message)),
      );
    });

    test('throws StateError when content-type header is incorrect', () async {
      const message = '''
Body could not be parsed as form data due to an invalid MIME type.
Expected MIME type: "application/x-www-form-urlencoded" OR "multipart/form-data"
Actual MIME type: "application/json"
''';
      expect(
        parseFormData(
          headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
          body: () async => '',
          bytes: () async* {},
        ),
        throwsA(isA<StateError>().having((e) => e.message, 'message', message)),
      );
    });

    test('returns empty form data when body is empty', () async {
      final formData = await parseFormData(
        headers: {
          HttpHeaders.contentTypeHeader: formUrlEncodedContentType.mimeType,
        },
        body: () async => '',
        bytes: () async* {},
      );

      expect(formData.fields, isEmpty);
      expect(formData.files, isEmpty);
    });

    test(
        'returns populated form data '
        'when body contains single key/value', () async {
      final formData = await parseFormData(
        headers: {
          HttpHeaders.contentTypeHeader: formUrlEncodedContentType.mimeType,
        },
        body: () async => 'foo=bar',
        bytes: () async* {},
      );

      expect(formData.fields, equals({'foo': 'bar'}));
      expect(formData.files, isEmpty);
    });

    test(
        'returns populated form data '
        'when body contains multiple key/values', () async {
      final formData = await parseFormData(
        headers: {
          HttpHeaders.contentTypeHeader: formUrlEncodedContentType.mimeType,
        },
        body: () async => 'foo=bar&bar=baz',
        bytes: () async* {},
      );

      expect(formData.fields, equals({'foo': 'bar', 'bar': 'baz'}));
      expect(formData.files, isEmpty);
    });

    group('multipart form-data', () {
      test('can parse a single field part', () async {
        final formData = await parseFormData(
          headers: {
            HttpHeaders.contentTypeHeader:
                'multipart/form-data; boundary=testing',
          },
          body: () async => '',
          bytes: () async* {
            const multiPartForm = MultiPartFormData('testing', [
              MultiPart('foo', 'bar'),
            ]);
            yield multiPartForm.toBytes();
          },
        );

        expect(formData.fields, equals({'foo': 'bar'}));
        expect(formData.files, isEmpty);
      });

      test('can parse a single file part', () async {
        final formData = await parseFormData(
          headers: {
            HttpHeaders.contentTypeHeader:
                'multipart/form-data; boundary=testing',
          },
          body: () async => '',
          bytes: () async* {
            final multiPartForm = MultiPartFormData('testing', [
              MultiPart(
                'my_file',
                'file content',
                fileName: 'my_file.txt',
                contentType: ContentType.text,
              ),
            ]);

            yield multiPartForm.toBytes();
          },
        );

        expect(formData.fields, isEmpty);
        expect(
          formData.files,
          equals({
            'my_file': isUploadedFile(
              'my_file.txt',
              ContentType.text,
              'file content',
            ),
          }),
        );
      });

      test('can parse multiple field and file parts', () async {
        final formData = await parseFormData(
          headers: {
            HttpHeaders.contentTypeHeader:
                'multipart/form-data; boundary=testing',
          },
          body: () async => '',
          bytes: () async* {
            final multiPartForm = MultiPartFormData('testing', [
              const MultiPart('foo', 'bar'),
              const MultiPart('bar', 'baz'),
              MultiPart(
                'my_file',
                'file content',
                fileName: 'my_file.txt',
                contentType: ContentType.text,
              ),
              MultiPart(
                'my_other_file',
                'file content',
                fileName: 'my_other_file.txt',
                contentType: ContentType.text,
              ),
            ]);

            yield multiPartForm.toBytes();
          },
        );

        expect(formData.fields, equals({'foo': 'bar', 'bar': 'baz'}));
        expect(
          formData.files,
          equals({
            'my_file': isUploadedFile(
              'my_file.txt',
              ContentType.text,
              'file content',
            ),
            'my_other_file': isUploadedFile(
              'my_other_file.txt',
              ContentType.text,
              'file content',
            ),
          }),
        );
      });
    });
  });

  group('$FormData', () {
    test('is backwards compatible with a Map<String, String>', () {
      final formData = FormData(
        fields: {'foo': 'bar', 'bar': 'baz'},
        files: {},
      );

      expect(formData['foo'], equals('bar'));
      expect(formData.keys, equals(['foo', 'bar']));
      expect(formData.values, equals(['bar', 'baz']));

      formData.remove('bar');
      expect(formData, equals({'foo': 'bar'}));
      expect(formData.fields, equals({'foo': 'bar'}));

      formData['bar'] = 'baz';
      expect(formData, equals({'foo': 'bar', 'bar': 'baz'}));
      expect(formData.fields, equals({'foo': 'bar', 'bar': 'baz'}));

      formData.clear();
      expect(formData, equals(isEmpty));
      expect(formData.fields, equals(isEmpty));
    });
  });

  group('$UploadedFile', () {
    test('toString', () {
      final byteStream = Stream.fromIterable([
        [1, 2, 3, 4],
      ]);
      final file = UploadedFile('name', ContentType.text, byteStream);

      expect(
        file.toString(),
        equals('{ name: name, contentType: text/plain; charset=utf-8 }'),
      );
    });

    test('readAsBytes', () async {
      final byteStream = Stream.fromIterable([
        [1, 2, 3, 4],
      ]);
      final file = UploadedFile('name', ContentType.text, byteStream);

      expect(
        await file.readAsBytes(),
        equals([1, 2, 3, 4]),
      );
    });

    test('openRead', () {
      final byteStream = Stream.fromIterable([
        [1, 2, 3, 4],
      ]);
      final file = UploadedFile('name', ContentType.text, byteStream);

      expect(
        file.openRead(),
        emitsInOrder([
          [1, 2, 3, 4],
        ]),
      );
    });
  });
}

Matcher isUploadedFile(String name, ContentType contentType, String content) {
  return isA<UploadedFile>()
      .having((f) => f.name, 'name', equals(name))
      .having(
        (f) => f.readAsBytes(),
        'name',
        completion(equals(utf8.encode(content))),
      )
      .having(
        (f) => f.contentType,
        'contentType',
        isA<ContentType>().having(
          (c) => c.primaryType,
          'primaryType',
          equals(contentType.primaryType),
        ),
      );
}

class MultiPartFormData {
  const MultiPartFormData(this.boundary, this.parts);

  final String boundary;

  final List<MultiPart> parts;

  List<int> toBytes() {
    return utf8.encode(
      [
        '',
        for (final part in parts) ...[
          '--$boundary ',
          '''content-disposition: form-data; name="${part.name}"${part.fileName != null ? ' filename="${part.fileName}"' : ''}''',
          if (part.contentType != null) 'content-type: ${part.contentType}',
          '',
          part.content,
        ],
        '--testing--',
        '',
      ].join('\r\n'),
    );
  }
}

class MultiPart {
  const MultiPart(
    this.name,
    this.content, {
    this.fileName,
    this.contentType,
  });

  final String name;

  final String content;

  final String? fileName;

  final ContentType? contentType;
}
