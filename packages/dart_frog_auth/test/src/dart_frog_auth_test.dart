// Not required for test files
// ignore_for_file: prefer_const_constructors
// Not required for test files
// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_auth/dart_frog_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockBearerAuthenticator extends Mock {
  Future<_User?> call(RequestContext context, String token);
}

class _User {
  const _User(this.id);
  final String id;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_MockRequestContext());
  });

  group('$basicAuthentication', () {
    late RequestContext context;
    late Request request;
    _User? user;

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      when(() => context.provide<_User>(any())).thenReturn(context);
      when(() => request.headers).thenReturn({});
      when(() => context.request).thenReturn(request);
    });

    group('using older API', () {
      test('returns 401 when Authorization header is not present', () async {
        final middleware = basicAuthentication<_User>(
          userFromCredentials: (_, __) async => user,
        );
        expect(
          await middleware((_) async => Response())(context),
          isA<Response>().having(
            (r) => r.statusCode,
            'statusCode',
            HttpStatus.unauthorized,
          ),
        );
      });

      test(
        'returns 401 when Authorization header is present but invalid',
        () async {
          when(() => request.headers)
              .thenReturn({'Authorization': 'not valid'});
          final middleware = basicAuthentication<_User>(
            userFromCredentials: (_, __) async => user,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.unauthorized,
            ),
          );
        },
      );

      test(
        'returns 401 when Authorization header is present and valid but no '
        'user is returned',
        () async {
          when(() => request.headers).thenReturn({
            'Authorization': 'Basic dXNlcjpwYXNz',
          });
          final middleware = basicAuthentication<_User>(
            userFromCredentials: (_, __) async => null,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.unauthorized,
            ),
          );
        },
      );

      test(
        'sets the user when everything is valid',
        () async {
          user = _User('');
          when(() => request.headers).thenReturn({
            'Authorization': 'Basic dXNlcjpwYXNz',
          });
          final middleware = basicAuthentication<_User>(
            userFromCredentials: (_, __) async => user,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.ok,
            ),
          );
          final captured = verify(() => context.provide<_User>(captureAny()))
              .captured
              .single;
          expect(
            (captured as _User Function()).call(),
            equals(user),
          );
        },
      );

      test("skips routes that doesn't match the custom predicate", () async {
        var called = false;

        final middleware = basicAuthentication<_User>(
          userFromCredentials: (_, __) async {
            called = true;
            return null;
          },
          applies: (_) async => false,
        );

        final response = await middleware((_) async => Response())(context);

        expect(called, isFalse);
        // By returning null on the userFromCredentials, if the middleware had
        // run we should have gotten a 401 response.
        expect(response.statusCode, equals(HttpStatus.ok));
      });
    });

    group('using the new API', () {
      test('returns 401 when Authorization header is not present', () async {
        final middleware = basicAuthentication<_User>(
          authenticator: (_, __, ___) async => user,
        );
        expect(
          await middleware((_) async => Response())(context),
          isA<Response>().having(
            (r) => r.statusCode,
            'statusCode',
            HttpStatus.unauthorized,
          ),
        );
      });

      test(
        'returns 401 when Authorization header is present but invalid',
        () async {
          when(() => request.headers)
              .thenReturn({'Authorization': 'not valid'});
          final middleware = basicAuthentication<_User>(
            authenticator: (_, __, ___) async => user,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.unauthorized,
            ),
          );
        },
      );

      test(
        'returns 401 when Authorization header is present and valid but no '
        'user is returned',
        () async {
          when(() => request.headers).thenReturn({
            'Authorization': 'Basic dXNlcjpwYXNz',
          });
          final middleware = basicAuthentication<_User>(
            authenticator: (_, __, ___) async => null,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.unauthorized,
            ),
          );
        },
      );

      test(
        'sets the user when everything is valid',
        () async {
          user = _User('');
          when(() => request.headers).thenReturn({
            'Authorization': 'Basic dXNlcjpwYXNz',
          });
          final middleware = basicAuthentication<_User>(
            authenticator: (_, __, ___) async => user,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.ok,
            ),
          );
          final captured = verify(() => context.provide<_User>(captureAny()))
              .captured
              .single;
          expect(
            (captured as _User Function()).call(),
            equals(user),
          );
        },
      );

      test("skips routes that doesn't match the custom predicate", () async {
        var called = false;

        final middleware = basicAuthentication<_User>(
          authenticator: (_, __, ___) async {
            called = true;
            return null;
          },
          applies: (_) async => false,
        );

        final response = await middleware((_) async => Response())(context);

        expect(called, isFalse);
        // By returning null on the userFromCredentials, if the middleware had
        // run we should have gotten a 401 response.
        expect(response.statusCode, equals(HttpStatus.ok));
      });
    });
  });

  group('$bearerAuthentication', () {
    late RequestContext context;
    late Request request;
    _User? user;

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      when(() => context.provide<_User>(any())).thenReturn(context);
      when(() => request.headers).thenReturn({});
      when(() => context.request).thenReturn(request);
    });

    group('using older API', () {
      test('returns 401 when Authorization header is not present', () async {
        final middleware = bearerAuthentication<_User>(
          userFromToken: (_) async => user,
        );
        expect(
          await middleware((_) async => Response())(context),
          isA<Response>().having(
            (r) => r.statusCode,
            'statusCode',
            HttpStatus.unauthorized,
          ),
        );
      });

      test(
        'returns 401 when Authorization header is present but invalid',
        () async {
          when(() => request.headers)
              .thenReturn({'Authorization': 'not valid'});
          final middleware = bearerAuthentication<_User>(
            userFromToken: (_) async => user,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.unauthorized,
            ),
          );
        },
      );

      test(
        'returns 401 when Authorization header is present and valid but no '
        'user is returned',
        () async {
          when(() => request.headers).thenReturn({
            'Authorization': 'Bearer 1234',
          });
          final middleware = bearerAuthentication<_User>(
            userFromToken: (_) async => null,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.unauthorized,
            ),
          );
        },
      );

      test(
        'sets the user when everything is valid',
        () async {
          user = _User('');
          when(() => request.headers).thenReturn({
            'Authorization': 'Bearer 1234',
          });
          final middleware = bearerAuthentication<_User>(
            userFromToken: (_) async => user,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.ok,
            ),
          );
          final captured = verify(() => context.provide<_User>(captureAny()))
              .captured
              .single;
          expect(
            (captured as _User Function()).call(),
            equals(user),
          );
        },
      );

      test('matches the scheme case-insensitively', () async {
        when(() => request.headers).thenReturn({
          'Authorization': 'bearer 1234',
        });
        String? received;
        final middleware = bearerAuthentication<_User>(
          userFromToken: (token) async {
            received = token;
            return _User('');
          },
        );
        final response = await middleware((_) async => Response())(context);
        expect(response.statusCode, equals(HttpStatus.ok));
        expect(received, equals('1234'));
      });

      test("skips routes that doesn't match the custom predicate", () async {
        var called = false;

        final middleware = bearerAuthentication<_User>(
          userFromToken: (_) async {
            called = true;
            return null;
          },
          applies: (_) async => false,
        );

        final response = await middleware((_) async => Response())(context);

        expect(called, isFalse);
        // By returning null on the userFromCredentials, if the middleware had
        // run we should have gotten a 401 response.
        expect(response.statusCode, equals(HttpStatus.ok));
      });
    });

    group('using the new API', () {
      test('returns 401 when Authorization header is not present', () async {
        final middleware = bearerAuthentication<_User>(
          authenticator: (_, __) async => user,
        );
        expect(
          await middleware((_) async => Response())(context),
          isA<Response>().having(
            (r) => r.statusCode,
            'statusCode',
            HttpStatus.unauthorized,
          ),
        );
      });

      test(
        'returns 401 when Authorization header is present but invalid',
        () async {
          when(() => request.headers)
              .thenReturn({'Authorization': 'not valid'});
          final middleware = bearerAuthentication<_User>(
            authenticator: (_, __) async => user,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.unauthorized,
            ),
          );
        },
      );

      test(
        'returns 401 when Authorization header is present and valid but no '
        'user is returned',
        () async {
          when(() => request.headers).thenReturn({
            'Authorization': 'Bearer 1234',
          });
          final middleware = bearerAuthentication<_User>(
            authenticator: (_, __) async => null,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.unauthorized,
            ),
          );
        },
      );

      test(
        'sets the user when everything is valid',
        () async {
          user = _User('');
          when(() => request.headers).thenReturn({
            'Authorization': 'Bearer 1234',
          });
          final middleware = bearerAuthentication<_User>(
            authenticator: (_, __) async => user,
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.ok,
            ),
          );
          final captured = verify(() => context.provide<_User>(captureAny()))
              .captured
              .single;
          expect(
            (captured as _User Function()).call(),
            equals(user),
          );
        },
      );

      group('parses the Authorization header', () {
        late _MockBearerAuthenticator authenticator;

        setUp(() {
          authenticator = _MockBearerAuthenticator();
          when(() => authenticator(any(), any()))
              .thenAnswer((_) async => _User(''));
        });

        for (final header in [
          'bearer 1234',
          'BEARER 1234',
          'Bearer   1234',
          'Bearer\t1234',
          '  Bearer 1234  ',
        ]) {
          test('authenticates ${jsonEncode(header)}', () async {
            when(() => request.headers).thenReturn({'Authorization': header});
            final middleware = bearerAuthentication<_User>(
              authenticator: authenticator.call,
            );
            final response = await middleware((_) async => Response())(context);
            expect(response.statusCode, equals(HttpStatus.ok));
            verify(() => authenticator(context, '1234')).called(1);
          });
        }

        for (final header in [
          'Bearer',
          'Bearer ',
          'Bearer 1234 extra',
          '',
          'Basic 1234',
        ]) {
          test('returns 401 for ${jsonEncode(header)}', () async {
            when(() => request.headers).thenReturn({'Authorization': header});
            final middleware = bearerAuthentication<_User>(
              authenticator: authenticator.call,
            );
            final response = await middleware((_) async => Response())(context);
            expect(response.statusCode, equals(HttpStatus.unauthorized));
            verifyNever(() => authenticator(any(), any()));
          });
        }
      });

      test("skips routes that doesn't match the custom predicate", () async {
        var called = false;

        final middleware = bearerAuthentication<_User>(
          authenticator: (_, __) async {
            called = true;
            return null;
          },
          applies: (_) async => false,
        );

        final response = await middleware((_) async => Response())(context);

        expect(called, isFalse);
        // By returning null on the userFromCredentials, if the middleware had
        // run we should have gotten a 401 response.
        expect(response.statusCode, equals(HttpStatus.ok));
      });
    });
  });

  group('$cookieAuthentication', () {
    late RequestContext context;
    late Request request;
    _User? user;

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      when(() => context.provide<_User>(any())).thenReturn(context);
      when(() => request.headers).thenReturn({});
      when(() => context.request).thenReturn(request);
    });

    test('returns 401 when Cookie header is not present', () async {
      final middleware = cookieAuthentication<_User>(
        authenticator: (_, __) async => user,
      );
      expect(
        await middleware((_) async => Response())(context),
        isA<Response>().having(
          (r) => r.statusCode,
          'statusCode',
          HttpStatus.unauthorized,
        ),
      );
    });

    test(
      'returns 401 when Cookie header is present but no user is returned',
      () async {
        when(() => request.headers).thenReturn({'Cookie': 'session=abc123'});
        final middleware = cookieAuthentication<_User>(
          authenticator: (_, __) async => null,
        );
        expect(
          await middleware((_) async => Response())(context),
          isA<Response>().having(
            (r) => r.statusCode,
            'statusCode',
            HttpStatus.unauthorized,
          ),
        );
      },
    );

    test(
      'sets the user when everything is valid',
      () async {
        user = _User('');
        when(() => request.headers).thenReturn({
          'Cookie': 'session=abc123',
        });
        final middleware = cookieAuthentication<_User>(
          authenticator: (_, __) async => user,
        );
        expect(
          await middleware((_) async => Response())(context),
          isA<Response>().having(
            (r) => r.statusCode,
            'statusCode',
            HttpStatus.ok,
          ),
        );
        final captured =
            verify(() => context.provide<_User>(captureAny())).captured.single;
        expect(
          (captured as _User Function()).call(),
          equals(user),
        );
      },
    );

    test("skips routes that doesn't match the custom predicate", () async {
      var called = false;

      final middleware = cookieAuthentication<_User>(
        authenticator: (_, __) async {
          called = true;
          return null;
        },
        applies: (_) async => false,
      );

      final response = await middleware((_) async => Response())(context);

      expect(called, isFalse);
      expect(response.statusCode, equals(HttpStatus.ok));
    });
  });
}
