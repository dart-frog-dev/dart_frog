// ignoring for testing purposes
// ignore_for_file: prefer_const_constructors
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:test/test.dart';

void main() {
  group('TestRequestContext', () {
    test('can be instantiated', () {
      expect(TestRequestContext(path: '/'), isNotNull);
    });

    test('creates the correct RequestContext', () {
      final testContext = TestRequestContext(
        path: '/',
        method: HttpMethod.post,
        headers: {'content-type': 'application/json'},
        body: 'hello world',
      );

      final context = testContext.context;
      expect(context.request.uri, equals(Uri.parse('https://test.com/')));
      expect(context.request.method, equals(HttpMethod.post));
      expect(
        context.request.headers,
        equals(
          {
            'content-type': 'application/json',
            'content-length': '11',
          },
        ),
      );
      expect(context.request.body(), completion(equals('hello world')));
    });

    test('can mock a dependency', () {
      final testContext = TestRequestContext(path: '/')
        ..provide<String>('hello');

      final context = testContext.context;
      expect(context.read<String>(), equals('hello'));
    });
  });
}
