// ignoring for testing purposes
// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:bearer_authentication/user_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/users/[id].dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('/users/[id]', () {
    late RequestContext context;
    late Request request;

    setUp(() {
      context = _MockRequestContext();

      request = _MockRequest();
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => context.request).thenReturn(request);
    });

    test('GET returns the current user', () async {
      final user = User(
        id: '1',
        name: 'John Doe',
        username: 'johndoe',
        password: '',
      );
      when(() => context.read<User>()).thenReturn(user);

      final response = await route.onRequest(context, '1');

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        await response.json(),
        equals(
          {
            'id': '1',
            'name': 'John Doe',
            'username': 'johndoe',
          },
        ),
      );
    });

    test('GET returns forbidden when accessing a different user', () async {
      final user = User(
        id: '1',
        name: 'John Doe',
        username: 'johndoe',
        password: '',
      );
      when(() => context.read<User>()).thenReturn(user);

      final response = await route.onRequest(context, '2');

      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    group('PATCH', () {
      test('updates the user', () async {
        final user = User(
          id: '1',
          name: 'John Doe',
          username: 'johndoe',
          password: '',
        );
        when(() => context.read<User>()).thenReturn(user);

        final userRepository = _MockUserRepository();
        when(
          () => userRepository.updateUser(
            id: '1',
            name: 'Jane Doe',
            username: 'janedoe',
            password: 'password',
          ),
        ).thenAnswer((_) async {});

        when(() => context.read<UserRepository>()).thenReturn(userRepository);

        when(() => request.method).thenReturn(HttpMethod.patch);
        when(() => request.json()).thenAnswer(
          (_) async => {
            'name': 'Jane Doe',
            'username': 'janedoe',
            'password': 'password',
          },
        );

        final response = await route.onRequest(context, '1');

        expect(response.statusCode, equals(HttpStatus.noContent));
        verify(
          () => userRepository.updateUser(
            id: '1',
            name: 'Jane Doe',
            username: 'janedoe',
            password: 'password',
          ),
        ).called(1);
      });

      test('returns bad content if there is no information to update',
          () async {
        final user = User(
          id: '1',
          name: 'John Doe',
          username: 'johndoe',
          password: '',
        );
        when(() => context.read<User>()).thenReturn(user);

        final userRepository = _MockUserRepository();
        when(() => context.read<UserRepository>()).thenReturn(userRepository);

        when(() => request.method).thenReturn(HttpMethod.patch);
        when(() => request.json()).thenAnswer(
          (_) async => <String, dynamic>{},
        );

        final response = await route.onRequest(context, '1');

        expect(response.statusCode, equals(HttpStatus.badRequest));
      });

      test(
        'returns forbidden when the logged user is not the requested one',
        () async {
          final user = User(
            id: '2',
            name: 'John Doe',
            username: 'johndoe',
            password: '',
          );
          when(() => context.read<User>()).thenReturn(user);

          final userRepository = _MockUserRepository();
          when(
            () => userRepository.updateUser(
              id: '1',
              name: 'Jane Doe',
              username: 'janedoe',
              password: 'password',
            ),
          ).thenAnswer((_) async {});

          when(() => context.read<UserRepository>()).thenReturn(userRepository);

          when(() => request.method).thenReturn(HttpMethod.patch);
          when(() => request.json()).thenAnswer(
            (_) async => {
              'name': 'Jane Doe',
              'username': 'janedoe',
              'password': 'password',
            },
          );

          final response = await route.onRequest(context, '1');

          expect(response.statusCode, equals(HttpStatus.forbidden));
        },
      );
    });

    group('DELETE', () {
      test('deletes the user', () async {
        final user = User(
          id: '1',
          name: 'John Doe',
          username: 'johndoe',
          password: '',
        );
        when(() => context.read<User>()).thenReturn(user);

        final userRepository = _MockUserRepository();
        when(() => userRepository.deleteUser('1')).thenAnswer((_) async {});

        when(() => context.read<UserRepository>()).thenReturn(userRepository);

        when(() => request.method).thenReturn(HttpMethod.delete);

        final response = await route.onRequest(context, '1');

        expect(response.statusCode, equals(HttpStatus.noContent));
        verify(() => userRepository.deleteUser('1')).called(1);
      });

      test('returns forbidden when deleting a different user', () async {
        final user = User(
          id: '1',
          name: 'John Doe',
          username: 'johndoe',
          password: '',
        );
        when(() => context.read<User>()).thenReturn(user);
        when(() => request.method).thenReturn(HttpMethod.delete);

        final response = await route.onRequest(context, '2');

        expect(response.statusCode, equals(HttpStatus.forbidden));
      });
    });

    test(
      'returns method not allowed when using an unsupported method',
      () async {
        when(() => request.method).thenReturn(HttpMethod.put);
        final response = await route.onRequest(context, '1');

        expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      },
    );
  });
}
