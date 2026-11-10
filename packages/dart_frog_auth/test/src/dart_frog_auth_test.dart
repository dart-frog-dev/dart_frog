// Not required for test files
// ignore_for_file: prefer_const_constructors
// Not required for test files
// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_auth/dart_frog_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _User {
  const _User(this.id);
  final String id;
}

void main() {
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

      test(
        'passes passwords that contain colons to the authenticator',
        () async {
          user = _User('');
          when(() => request.headers).thenReturn({
            'Authorization': 'Basic dXNlcjpwYTpzcw==',
          });
          String? username;
          String? password;
          final middleware = basicAuthentication<_User>(
            authenticator: (_, u, p) async {
              username = u;
              password = p;
              return user;
            },
          );
          expect(
            await middleware((_) async => Response())(context),
            isA<Response>().having(
              (r) => r.statusCode,
              'statusCode',
              HttpStatus.ok,
            ),
          );
          expect(username, equals('user'));
          expect(password, equals('pa:ss'));
        },
      );

      for (final token in ['dXNlcg==', '', 'not-base64!']) {
        test(
          'returns 401 when Authorization header has malformed credentials '
          '("$token")',
          () async {
            var called = false;
            when(() => request.headers).thenReturn({
              'Authorization': 'Basic $token',
            });
            final middleware = basicAuthentication<_User>(
              authenticator: (_, __, ___) async {
                called = true;
                return user;
              },
            );
            expect(
              await middleware((_) async => Response())(context),
              isA<Response>().having(
                (r) => r.statusCode,
                'statusCode',
                HttpStatus.unauthorized,
              ),
            );
            expect(called, isFalse);
          },
        );
      }

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

    for (final (header, expected) in [
      ('session=abc==; theme=dark', {'session': 'abc==', 'theme': 'dark'}),
      ('session=a=b', {'session': 'a=b'}),
      ('session=abc;theme=dark', {'session': 'abc', 'theme': 'dark'}),
      ('session=abc; theme=dark;', {'session': 'abc', 'theme': 'dark'}),
      ('flag; session=abc', {'session': 'abc'}),
      ('session=', {'session': ''}),
      ('', <String, String>{}),
    ]) {
      test('parses the Cookie header "$header"', () async {
        Map<String, String>? cookies;
        when(() => request.headers).thenReturn({'Cookie': header});
        final middleware = cookieAuthentication<_User>(
          authenticator: (_, c) async {
            cookies = c;
            return null;
          },
        );
        expect(
          await middleware((_) async => Response())(context),
          isA<Response>().having(
            (r) => r.statusCode,
            'statusCode',
            HttpStatus.unauthorized,
          ),
        );
        expect(cookies, equals(expected));
      });
    }

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
