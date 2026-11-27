import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/users/%5Bid%5D/%5Bname%5D.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('GET /', () {
    test('responds with a 200 and greeting + name + id', () {
      const greeting = 'Hello';
      const id = 'id';
      const name = 'Frog';
      final context = _MockRequestContext();
      when(() => context.read<String>()).thenReturn(greeting);
      final response = route.onRequest(context, id, name);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.body(), completion(equals('$greeting $name (user $id)')));
    });
  });
}
