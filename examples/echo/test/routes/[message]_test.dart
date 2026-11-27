import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/%5Bmessage%5D.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('GET /<message>', () {
    test('responds with a 200 and echos the message.', () async {
      const message = 'echo';
      final context = _MockRequestContext();
      final response = route.onRequest(context, message);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.body(), completion(equals(message)));
    });
  });
}
