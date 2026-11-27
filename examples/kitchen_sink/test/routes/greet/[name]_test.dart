import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/greet/%5Bname%5D.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('GET /', () {
    test('responds with a 200 and greeting + name', () {
      const greeting = 'Hello';
      const name = 'Frog';
      final context = _MockRequestContext();
      when(() => context.read<String>()).thenReturn(greeting);
      final response = route.onRequest(context, name);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.body(), completion(equals('$greeting $name')));
    });
  });
}
