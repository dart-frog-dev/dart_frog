// ignoring for testing purposes
// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:bearer_authentication/user_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/users/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('/users', () {
    late RequestContext context;
    late Request request;
    late UserRepository userRepository;

    setUp(() {
      context = _MockRequestContext();

      userRepository = _MockUserRepository();
      when(() => context.read<UserRepository>()).thenReturn(userRepository);

      request = _MockRequest();
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.request).thenReturn(request);
    });

    test('POST creates a new user and returns its id', () async {
      when(() => request.json()).thenAnswer(
        (_) async => {
          'name': 'John Doe',
          'username': 'johndoe',
          'password': '123',
        },
      );
      when(
        () => userRepository.createUser(
          name: 'John Doe',
          username: 'johndoe',
          password: '123',
        ),
      ).thenAnswer((_) async => '123');

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        await response.json(),
        equals(
          {
            'id': '123',
          },
        ),
      );
    });

    test('returns bad request when name is missing', () async {
      when(() => request.json()).thenAnswer(
        (_) async => {
          'username': 'johndoe',
          'password': '123',
        },
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns bad request when username is missing', () async {
      when(() => request.json()).thenAnswer(
        (_) async => {
          'name': 'John Doe',
          'password': '123',
        },
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns bad request when password is missing', () async {
      when(() => request.json()).thenAnswer(
        (_) async => {
          'username': 'johndoe',
          'name': 'John Doe',
        },
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test(
      'returns method not allowed when using an unsupported method',
      () async {
        when(() => request.method).thenReturn(HttpMethod.put);
        final response = await route.onRequest(context);

        expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      },
    );
  });
}
