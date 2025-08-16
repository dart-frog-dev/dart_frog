import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog/src/_internal.dart';
import 'package:dart_frog/src/body_parsers/body_parsers.dart';
import 'package:test/test.dart';

void main() {
  group('Request', () {
    final localhost = Uri.parse('http://localhost/');

    test('has correct url', () {
      final request = Request('GET', localhost);
      expect(request.url, equals(Uri()));
    });

    test('has correct uri', () {
      final request = Request('GET', localhost);
      expect(request.uri, equals(localhost));
    });

    test('has correct body (empty)', () {
      final request = Request('GET', localhost);
      expect(request.body(), completion(isEmpty));
    });

    test('has correct body (string)', () {
      const body = '__test_body__';
      final request = Request('GET', localhost, body: body);
      expect(request.body(), completion(equals(body)));
    });

    test('has correct body (json)', () {
      const body = {'test': 'body'};
      final request = Request('GET', localhost, body: json.encode(body));
      expect(request.json(), completion(equals(body)));
    });

    test('has correct body (byte array)', () {
      const body = 'hello';
      final request = Request('GET', localhost, body: utf8.encode(body));
      expect(request.bytes(), emits(utf8.encode(body)));
    });

    test('throw exception when method is unsupported', () {
      final request = Request('FOO', localhost);
      expect(
        () => request.method,
        throwsA(
          isA<UnsupportedHttpMethodException>()
              .having((e) => e.toString(), 'toString', '''
Unsupported HTTP method: FOO. 
The following methods are supported:
${HttpMethod.values.map((m) => m.value.toUpperCase()).join(', ')}.'''),
        ),
      );
    });

    test('throws exception when unable to read body', () async {
      final exception = Exception('oops');
      final body = Stream<Object>.error(exception);
      final request = Request('GET', localhost, body: body);
      expect(request.body, throwsA(exception));
    });

    test('throws exception when unable to read body multiple times', () async {
      final exception = Exception('oops');
      final body = Stream<Object>.error(exception);
      final request = Request('GET', localhost, body: body);
      expect(request.body, throwsA(exception));
      expect(request.body, throwsA(exception));
    });

    test('has correct headers', () {
      const headers = <String, String>{'foo': 'bar'};
      final request = Request('GET', localhost, headers: headers);
      expect(request.headers['foo'], equals(headers['foo']));
    });

    test('has correct params (empty)', () {
      final request = Request('GET', localhost);
      expect(
        request.params,
        equals(UnmodifiableMapView<String, String>(const {})),
      );
    });

    test('body can be read multiple times (sync)', () {
      final body = json.encode({'test': 'body'});
      final request = Request('GET', localhost, body: body);

      expect(request.body(), completion(equals(body)));
      expect(request.body(), completion(equals(body)));

      expect(request.json(), completion(equals(json.decode(body))));
      expect(request.json(), completion(equals(json.decode(body))));
    });

    test('body can be read multiple times (async)', () async {
      final body = json.encode({'test': 'body'});
      final request = Request('GET', localhost, body: body);

      await expectLater(request.body(), completion(equals(body)));
      await expectLater(request.body(), completion(equals(body)));

      await expectLater(request.json(), completion(equals(json.decode(body))));
      await expectLater(request.json(), completion(equals(json.decode(body))));
    });

    group('copyWith', () {
      test('returns a copy with overridden properties', () {
        const headers = <String, String>{'foo': 'bar'};
        const path = '';
        const body = 'test-body';
        final original = Request('GET', localhost);
        final copy = original.copyWith(
          headers: headers,
          path: path,
          body: body,
        );
        expect(copy.method, equals(HttpMethod.get));
        expect(copy.headers['foo'], equals(headers['foo']));
        expect(copy.url, equals(Uri()));
        expect(copy.body(), completion(equals(body)));
      });
    });

    group('delete', () {
      test('has correct method', () {
        final request = Request.delete(localhost);
        expect(request.method, equals(HttpMethod.delete));
      });
    });

    group('get', () {
      test('has correct method', () {
        final request = Request.get(localhost);
        expect(request.method, equals(HttpMethod.get));
      });
    });

    group('patch', () {
      test('has correct method', () {
        final request = Request.patch(localhost);
        expect(request.method, equals(HttpMethod.patch));
      });
    });

    group('post', () {
      test('has correct method', () {
        final request = Request.post(localhost);
        expect(request.method, equals(HttpMethod.post));
      });
    });

    group('put', () {
      test('has correct method', () {
        final request = Request.put(localhost);
        expect(request.method, equals(HttpMethod.put));
      });
    });

    group('bytes', () {
      test('has correct body', () {
        final bytes = utf8.encode('hello');
        final request = Request.get(localhost, body: bytes);
        expect(request.bytes(), emits(equals(bytes)));
      });
    });

    group('formData', () {
      final contentTypeFormUrlEncoded = {
        HttpHeaders.contentTypeHeader: formUrlEncodedContentType.mimeType,
      };

      test('throws StateError on invalid content-type', () async {
        final request = Request.post(localhost);
        expect(request.formData(), throwsStateError);
      });

      test('has correct data (no body)', () async {
        final request = Request.post(
          localhost,
          headers: contentTypeFormUrlEncoded,
        );
        expect(request.formData(), completion(equals({})));
      });

      test('has correct data (empty body)', () async {
        final request = Request.post(
          localhost,
          headers: contentTypeFormUrlEncoded,
          body: '',
        );
        expect(request.formData(), completion(equals({})));
      });

      test('has correct data (single key/value pair)', () async {
        final request = Request.post(
          localhost,
          headers: contentTypeFormUrlEncoded,
          body: 'foo=bar',
        );
        expect(request.formData(), completion(equals({'foo': 'bar'})));
      });

      test('has correct data (multiple key/value pairs)', () async {
        final request = Request.post(
          localhost,
          headers: contentTypeFormUrlEncoded,
          body: 'foo=bar&bar=baz',
        );
        expect(
          request.formData(),
          completion(equals({'foo': 'bar', 'bar': 'baz'})),
        );
      });
    });

    group('json', () {
      test('has correct body (map)', () {
        final body = <String, dynamic>{'foo': 'bar'};
        final request = Request.get(localhost, body: json.encode(body));
        expect(request.json(), completion(equals(body)));
      });

      test('has correct body (list)', () {
        final body = <String>['foo', 'bar'];
        final request = Request.get(localhost, body: json.encode(body));
        expect(request.json(), completion(equals(body)));
      });

      test('has correct body (string)', () {
        const body = 'foo';
        final request = Request.get(localhost, body: json.encode(body));
        expect(request.json(), completion(equals(body)));
      });

      test('has correct body (number)', () {
        const body = 42.0;
        final request = Request.get(localhost, body: json.encode(body));
        expect(request.json(), completion(equals(body)));
      });

      test('has correct body (bool)', () {
        const body = false;
        final request = Request.get(localhost, body: json.encode(body));
        expect(request.json(), completion(equals(body)));
      });
    });
  });
}
