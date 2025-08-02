// ignoring for testing purposes
// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:bearer_authentication/hash_extension.dart';
import 'package:bearer_authentication/session_repository.dart';
import 'package:bearer_authentication/user_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/auth/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  group('/auth', () {
    late RequestContext context;
    late Request request;
    late UserRepository userRepository;
    late SessionRepository sessionRepository;

    setUp(() {
      context = _MockRequestContext();

      userRepository = _MockUserRepository();
      when(() => context.read<UserRepository>()).thenReturn(userRepository);

      sessionRepository = _MockSessionRepository();
      when(() => context.read<SessionRepository>())
          .thenReturn(sessionRepository);

      request = _MockRequest();
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.request).thenReturn(request);
    });

    test('POST creates authenticates the user', () async {
      when(() => request.json()).thenAnswer(
        (_) async => {
          'username': 'johndoe',
          'password': '123',
        },
      );

      final user = User(
        id: '123',
        username: 'johndoe',
        name: 'John Doe',
        password: '123'.hashValue,
      );

      when(
        () => userRepository.userFromCredentials(
          'johndoe',
          '123',
        ),
      ).thenAnswer((_) async => user);

      when(() => sessionRepository.createSession('123')).thenAnswer(
        (_) async => Session(
          token: 'abc',
          userId: '123',
          createdAt: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 1)),
        ),
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        await response.json(),
        equals(
          {
            'token': 'abc',
          },
        ),
      );
    });

    test('returns unauthorized when the credentials are wrong', () async {
      when(() => request.json()).thenAnswer(
        (_) async => {
          'username': 'johndoe',
          'password': '123',
        },
      );

      when(
        () => userRepository.userFromCredentials(
          'johndoe',
          '123',
        ),
      ).thenAnswer((_) async => null);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns bad request when username is missing', () async {
      when(() => request.json()).thenAnswer(
        (_) async => {
          'password': '123',
        },
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns bad request when password is missing', () async {
      when(() => request.json()).thenAnswer(
        (_) async => {
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
