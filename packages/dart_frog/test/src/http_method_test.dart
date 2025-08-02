// ignoring for testing purposes
// ignore_for_file: prefer_const_declarations

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

void main() {
  group('HttpMethod', () {
    group('GET', () {
      test('has correct value and toString', () {
        final method = HttpMethod.get;
        expect(method.value, equals('GET'));
        expect(method.toString(), equals('HttpMethod.get'));
      });
    });

    group('DELETE', () {
      test('has correct value and toString', () {
        final method = HttpMethod.delete;
        expect(method.value, equals('DELETE'));
        expect(method.toString(), equals('HttpMethod.delete'));
      });
    });

    group('PATCH', () {
      test('has correct value and toString', () {
        final method = HttpMethod.patch;
        expect(method.value, equals('PATCH'));
        expect(method.toString(), equals('HttpMethod.patch'));
      });
    });

    group('POST', () {
      test('has correct value and toString', () {
        final method = HttpMethod.post;
        expect(method.value, equals('POST'));
        expect(method.toString(), equals('HttpMethod.post'));
      });
    });

    group('PUT', () {
      test('has correct value and toString', () {
        final method = HttpMethod.put;
        expect(method.value, equals('PUT'));
        expect(method.toString(), equals('HttpMethod.put'));
      });
    });
  });
}
