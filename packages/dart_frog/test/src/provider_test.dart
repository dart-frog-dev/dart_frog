import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  test('values can be provided and read via middleware', () async {
    const value = '__test_value__';
    String? nullableValue;
    Handler middleware(Handler handler) {
      return handler
          .use(provider<String>((_) => value))
          .use(provider<String?>((_) => nullableValue));
    }

    Response onRequest(RequestContext context) {
      final value = context.read<String>();
      final nullableValue = context.read<String?>();
      return Response(body: '$value:$nullableValue');
    }

    final handler =
        const Pipeline().addMiddleware(middleware).addHandler(onRequest);

    final server = await serve(handler, 'localhost', 3010);
    final client = http.Client();
    final response = await client.get(Uri.parse('http://localhost:3010/'));

    await expectLater(response.statusCode, equals(HttpStatus.ok));
    await expectLater(response.body, equals('$value:$nullableValue'));

    await server.close();
  });

  test('descendant providers can access provided values', () async {
    const url = 'http://localhost/';
    Handler middleware(Handler handler) {
      return handler
          .use(provider<Uri>((context) => Uri.parse(context.read<String>())))
          .use(provider<String>((context) => url));
    }

    Response onRequest(RequestContext context) {
      final value = context.read<Uri>();
      return Response(body: value.toString());
    }

    final handler =
        const Pipeline().addMiddleware(middleware).addHandler(onRequest);

    final server = await serve(handler, 'localhost', 3011);
    final client = http.Client();
    final response = await client.get(Uri.parse('http://localhost:3011/'));

    await expectLater(response.statusCode, equals(HttpStatus.ok));
    await expectLater(response.body, equals(url));

    await server.close();
  });

  test('A StateError is thrown when reading an un-provided value', () async {
    Object? exception;
    Response onRequest(RequestContext context) {
      try {
        context.read<Uri>();
        // ignoring since we need to catch the StateError for testing
        // ignore: avoid_catches_without_on_clauses
      } catch (e) {
        exception = e;
      }
      return Response();
    }

    final handler = const Pipeline()
        .addMiddleware((handler) => handler)
        .addHandler(onRequest);

    final server = await serve(handler, 'localhost', 3012);
    final client = http.Client();
    final response = await client.get(Uri.parse('http://localhost:3012/'));

    await expectLater(response.statusCode, equals(HttpStatus.ok));
    expect(exception, isA<StateError>());

    await server.close();
  });
}
