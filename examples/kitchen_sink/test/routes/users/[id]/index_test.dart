import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/users/%5Bid%5D/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('GET /', () {
    test('responds with a 200 and greeting + id', () {
      const greeting = 'Hello';
      const id = 'id';
      final context = _MockRequestContext();
      when(() => context.read<String>()).thenReturn(greeting);
      final response = route.onRequest(context, id);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.body(), completion(equals('$greeting user $id')));
    });
  });
}
