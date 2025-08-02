import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog/src/body_parsers/form_data.dart';
import 'package:test/test.dart';

void main() {
  group('Response', () {
    group('statusCode', () {
      test('defaults to 200.', () {
        final response = Response();
        expect(response.statusCode, equals(HttpStatus.ok));
      });

      test('can be overridden.', () {
        const expected = HttpStatus.notFound;
        final response = Response(statusCode: expected);
        expect(response.statusCode, equals(expected));
      });
    });

    test('has correct body (string)', () {
      const body = 'test-body';
      final response = Response(body: body);
      expect(response.body(), completion(equals(body)));
    });

    test('has correct body (empty)', () {
      final response = Response();
      expect(response.body(), completion(isEmpty));
    });

    test('throws exception when unable to read body', () async {
      final request = Response.bytes(body: base64Decode('1234'));
      expect(request.body, throwsException);
    });

    test('throws exception when unable to read body multiple times.', () async {
      final request = Response.bytes(body: base64Decode('1234'));
      expect(request.body, throwsException);
      expect(request.body, throwsException);
    });

    test('has correct headers', () {
      const headers = <String, String>{'foo': 'bar'};
      final response = Response(headers: headers);
      expect(response.headers['foo'], equals('bar'));
    });

    test('has correct headers when a key has multiple values', () {
      const headers = <String, Object>{
        'foo': ['bar', 'baz'],
      };
      final response = Response(headers: headers);
      expect(response.headers['foo'], equals('bar,baz'));
    });

    test('body can be read multiple times (sync)', () {
      final body = json.encode({'test': 'body'});
      final response = Response(body: body);

      expect(response.body(), completion(equals(body)));
      expect(response.body(), completion(equals(body)));

      expect(response.json(), completion(equals(json.decode(body))));
      expect(response.json(), completion(equals(json.decode(body))));
    });

    test('body can be read multiple times (async)', () async {
      final body = json.encode({'test': 'body'});
      final response = Response(body: body);

      await expectLater(response.body(), completion(equals(body)));
      await expectLater(response.body(), completion(equals(body)));

      await expectLater(response.json(), completion(equals(json.decode(body))));
      await expectLater(response.json(), completion(equals(json.decode(body))));
    });

    group('copyWith', () {
      test('returns a copy with overridden properties', () {
        const headers = <String, String>{'foo': 'bar'};
        const body = 'test-body';
        final original = Response();
        final copy = original.copyWith(
          headers: headers,
          body: body,
        );
        expect(copy.headers['foo'], equals(headers['foo']));
        expect(copy.body(), completion(equals(body)));
      });
    });

    group('bytes', () {
      test('has correct body', () {
        final bytes = utf8.encode('hello');
        final response = Response.bytes(body: bytes);
        expect(response.bytes(), emits(equals(bytes)));
      });
    });

    group('stream', () {
      test('has correct body', () {
        final bytes = utf8.encode('hello');
        final stream = Stream.value(bytes);
        final response = Response.stream(body: stream);
        expect(response.bytes(), emits(equals(bytes)));
      });

      group('bufferOutput', () {
        test('is omitted by default', () {
          final response = Response.stream(body: const Stream.empty());

          expect(
            response.context,
            isNot(contains(Response.shelfBufferOutputContextKey)),
            reason:
                '''The context should not have the '${Response.shelfBufferOutputContextKey}' key.''',
          );
        });

        test('can be disabled', () {
          final response = Response.stream(
            body: const Stream.empty(),
            bufferOutput: false,
          );

          expect(
            response.context,
            contains(Response.shelfBufferOutputContextKey),
            reason:
                '''The context should have the '${Response.shelfBufferOutputContextKey}' key.''',
          );

          final bufferOutput =
              response.context[Response.shelfBufferOutputContextKey];
          expect(
            bufferOutput,
            isFalse,
            reason:
                '''The '${Response.shelfBufferOutputContextKey}' should be 'false' when disabled.''',
          );
        });
      });
    });

    group('formData', () {
      final contentTypeFormUrlEncoded = {
        HttpHeaders.contentTypeHeader: formUrlEncodedContentType.mimeType,
      };

      test('throws StateError on invalid content-type', () async {
        final response = Response();
        expect(response.formData(), throwsStateError);
      });

      test('has correct data (no body)', () async {
        final response = Response(headers: contentTypeFormUrlEncoded);
        expect(response.formData(), completion(equals({})));
      });

      test('has correct data (empty body)', () async {
        final response = Response(headers: contentTypeFormUrlEncoded, body: '');
        expect(response.formData(), completion(equals({})));
      });

      test('has correct data (single key/value pair)', () async {
        final response = Response(
          headers: contentTypeFormUrlEncoded,
          body: 'foo=bar',
        );
        expect(response.formData(), completion(equals({'foo': 'bar'})));
      });

      test('has correct data (multiple key/value pairs)', () async {
        final response = Response(
          headers: contentTypeFormUrlEncoded,
          body: 'foo=bar&bar=baz',
        );
        expect(
          response.formData(),
          completion(equals({'foo': 'bar', 'bar': 'baz'})),
        );
      });
    });

    group('json', () {
      test('has correct body (map)', () {
        final body = <String, dynamic>{'foo': 'bar'};
        final response = Response.json(body: body);
        expect(response.json(), completion(equals(body)));
      });

      test('has correct body (list)', () {
        final body = <String>['foo', 'bar'];
        final response = Response.json(body: body);
        expect(response.json(), completion(equals(body)));
      });

      test('has correct body (string)', () {
        const body = 'foo';
        final response = Response.json(body: body);
        expect(response.json(), completion(equals(body)));
      });

      test('has correct body (number)', () {
        const body = 42.0;
        final response = Response.json(body: body);
        expect(response.json(), completion(equals(body)));
      });

      test('has correct body (bool)', () {
        const body = false;
        final response = Response.json(body: body);
        expect(response.json(), completion(equals(body)));
      });

      test('has correct body (empty)', () {
        final response = Response.json();
        expect(response.json(), completion(isEmpty));
      });

      test('has correct content-type when overriden in headers', () {
        final headers = <String, String>{
          HttpHeaders.contentTypeHeader: ContentType.html.value,
        };
        final response = Response.json(headers: headers);
        expect(
          response.headers[HttpHeaders.contentTypeHeader],
          equals(ContentType.html.value),
        );
      });
    });

    group('movedPermanently', () {
      test('has correct location url', () {
        final response = Response.movedPermanently(
          location: 'test-location',
        );
        expect(
          response.headers[HttpHeaders.locationHeader],
          equals('test-location'),
        );
      });

      test('has correct body', () {
        final response = Response.movedPermanently(
          location: 'location',
          body: 'body',
        );
        expect(response.body(), completion('body'));
      });

      test('has correct body (string)', () {
        final response = Response.movedPermanently(
          location: 'location',
          body: 'body',
        );
        expect(response.body(), completion('body'));
      });

      test('has correct body (empty)', () {
        final response = Response.movedPermanently(
          location: 'location',
        );
        expect(response.body(), completion(isEmpty));
      });

      test('has correct body (json)', () {
        final response = Response.movedPermanently(
          location: 'location',
          body: jsonEncode(
            <String, dynamic>{'foo': 'bar'},
          ),
        );
        expect(
          response.json(),
          completion(<String, dynamic>{'foo': 'bar'}),
        );
      });

      test('has correct headers', () {
        const headers = <String, String>{'foo': 'bar'};
        final response = Response.movedPermanently(
          location: 'location',
          headers: headers,
        );
        expect(response.headers['foo'], equals('bar'));
        expect(
          response.headers[HttpHeaders.locationHeader],
          equals('location'),
        );
      });
    });
  });
}
