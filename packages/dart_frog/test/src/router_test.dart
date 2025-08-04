// Copyright 2019 Google LLC
// Copyright 2022 Very Good Ventures
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog/src/_internal.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockShelfRequest extends Mock implements shelf.Request {}

void main() {
  // Create a server that listens on localhost for testing
  late io.IOServer server;

  setUp(() async {
    try {
      server = await io.IOServer.bind(InternetAddress.loopbackIPv6, 0);
    } on SocketException catch (_) {
      server = await io.IOServer.bind(InternetAddress.loopbackIPv4, 0);
    }
  });

  tearDown(() => server.close());

  test('throws ArgumentError when route does not start with a slash', () {
    expect(
      () => Router()..all('hello', (RequestContext context) => Response()),
      throwsArgumentError,
    );
  });

  test('add throws ArgumentError when verb is not valid', () {
    expect(
      () => Router()
        ..add('hello', '/route', (RequestContext context) => Response()),
      throwsArgumentError,
    );
  });

  test('mount throws ArgumentError when route does not start with a slash', () {
    expect(
      () => Router()
        ..mount(
          'hello',
          (RequestContext context) => Response(body: 'not-found'),
        ),
      throwsArgumentError,
    );
  });

  test('all handler', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..all('/hello/world', (RequestContext context) {
        return Response(body: 'hello');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    var response = await http.get(Uri.parse('${server.url}/wrong-path'));
    expect(response.statusCode, equals(HttpStatus.notFound));
    expect(response.body, equals('Route not found'));

    final streamedResponse = await http.Client().send(
      http.Request('FOO', Uri.parse('${server.url}/hello/world')),
    );
    response = await http.Response.fromStream(streamedResponse);
    expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    expect(response.body, equals('Method not allowed'));

    response = await http.get(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, equals('hello'));
  });

  test('delete handler', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..delete('/hello/world', (RequestContext context) {
        return Response(body: 'hello');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    var response = await http.get(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.notFound));
    expect(response.body, equals('Route not found'));

    response = await http.delete(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, equals('hello'));
  });

  test('get handler', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..get('/hello/world', (RequestContext context) {
        return Response(body: 'hello');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    var response = await http.get(Uri.parse('${server.url}/wrong-path'));
    expect(response.statusCode, equals(HttpStatus.notFound));
    expect(response.body, equals('Route not found'));

    response = await http.head(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, isEmpty);

    response = await http.get(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, equals('hello'));
  });

  test('head handler', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..head('/hello/world', (RequestContext context) {
        return Response();
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    var response = await http.head(Uri.parse('${server.url}/wrong-path'));
    expect(response.statusCode, equals(HttpStatus.notFound));
    expect(response.body, isEmpty);

    response = await http.head(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, isEmpty);
  });

  test('options handler', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..options('/hello/world', (RequestContext context) {
        return Response(body: 'hello');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    final client = http.Client();
    var streamedResponse = await client.send(
      http.Request('OPTIONS', Uri.parse('${server.url}/wrong-path')),
    );
    var response = await http.Response.fromStream(streamedResponse);
    expect(response.statusCode, equals(HttpStatus.notFound));
    expect(response.body, equals('Route not found'));

    streamedResponse = await client.send(
      http.Request('OPTIONS', Uri.parse('${server.url}/hello/world')),
    );
    response = await http.Response.fromStream(streamedResponse);
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, equals('hello'));

    client.close();
  });

  test('patch handler', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..patch('/hello/world', (RequestContext context) {
        return Response(body: 'hello');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    var response = await http.get(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.notFound));
    expect(response.body, equals('Route not found'));

    response = await http.patch(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, equals('hello'));
  });

  test('post handler', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..post('/hello/world', (RequestContext context) {
        return Response(body: 'hello');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    var response = await http.get(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.notFound));
    expect(response.body, equals('Route not found'));

    response = await http.post(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, equals('hello'));
  });

  test('put handler', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..put('/hello/world', (RequestContext context) {
        return Response(body: 'hello');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    var response = await http.get(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.notFound));
    expect(response.body, equals('Route not found'));

    response = await http.put(Uri.parse('${server.url}/hello/world'));
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, equals('hello'));
  });

  test('request exposes captured params (empty)', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..get('/hello', (RequestContext context) {
        expect(context.request.params, isEmpty);
        return Response(body: 'hello world');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    final response = await http.get(Uri.parse('${server.url}/hello'));
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, equals('hello world'));
  });

  test('request exposes captured params (single)', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..get('/users/<id>/greet', (RequestContext context, String id) {
        expect(context.request.params['id'], equals(id));
        return Response(body: 'hello $id');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    final response = await http.get(Uri.parse('${server.url}/users/42/greet'));
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, equals('hello 42'));
  });

  test('request exposes captured params (multiple)', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..get('/users/<id>/greet/<name>',
          (RequestContext context, String id, String name) {
        expect(context.request.params['id'], equals(id));
        expect(context.request.params['name'], equals(name));
        return Response(body: 'hello $name ($id)');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    final response =
        await http.get(Uri.parse('${server.url}/users/42/greet/felangel'));
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(response.body, equals('hello felangel (42)'));
  });

  test('mount(Router)', () async {
    final context = _MockRequestContext();
    final api = Router()
      ..all('/user/<user>/info', (RequestContext context, String user) {
        return Response(body: 'Hello $user');
      });

    final app = Router()
      ..all('/hello', (RequestContext context) => Response(body: 'hello-world'))
      ..mount('/api/', api.call)
      ..all(
        '/<_|[^]*>',
        (RequestContext context) => Response(body: 'catch-all-handler'),
      );

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app.call(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    var response = await http.get(Uri.parse('${server.url}/hello'));
    expect(response.body, equals('hello-world'));

    response = await http.get(
      Uri.parse('${server.url}/api/user/felangel/info'),
    );
    expect(response.body, equals('Hello felangel'));

    response = await http.get(
      Uri.parse('${server.url}/api/user/felangel/info-wrong'),
    );
    expect(response.body, equals('catch-all-handler'));
  });

  test('mount(Handler) with middleware', () async {
    final context = _MockRequestContext();
    final api = Router()
      ..all('/hello', (RequestContext context) {
        return Response(body: 'Hello');
      });

    Handler middleware(Handler handler) {
      return (context) {
        if (context.request.url.queryParameters.containsKey('ok')) {
          return Response(body: 'middleware');
        }
        return handler(context);
      };
    }

    final app = Router()
      ..mount(
        '/api/',
        const Pipeline().addMiddleware(middleware).addHandler(api.call),
      );

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app.call(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    var response = await http.get(Uri.parse('${server.url}/api/hello'));
    expect(response.body, equals('Hello'));

    response = await http.get(Uri.parse('${server.url}/api/hello?ok'));
    expect(response.body, equals('middleware'));
  });

  test('mount(Router) does not require a trailing slash', () async {
    final context = _MockRequestContext();
    final api = Router()
      ..all('/', (RequestContext context) => Response(body: 'Hello World!'))
      ..all('/user/<user>/info', (RequestContext context, String user) {
        return Response(body: 'Hello $user');
      });

    final app = Router()
      ..all('/hello', (RequestContext context) {
        return Response(body: 'hello-world');
      })
      ..mount('/api', api.call)
      ..all('/<_|[^]*>', (RequestContext context) {
        return Response(body: 'catch-all-handler');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app.call(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    var response = await http.get(Uri.parse('${server.url}/hello'));
    expect(response.body, equals('hello-world'));

    response = await http.get(Uri.parse('${server.url}/api'));
    expect(response.body, equals('Hello World!'));

    response = await http.get(Uri.parse('${server.url}/api/'));
    expect(response.body, equals('Hello World!'));

    response = await http.get(
      Uri.parse('${server.url}/api/user/felangel/info'),
    );
    expect(response.body, equals('Hello felangel'));

    response = await http.get(
      Uri.parse('${server.url}/api/user/felangel/info-wrong'),
    );
    expect(response.body, equals('catch-all-handler'));
  });

  test('can invoke custom handler if no route matches', () async {
    final context = _MockRequestContext();
    final app =
        Router(notFoundHandler: (req) => Response(body: 'Not found, but ok'))
          ..all('/hello', (RequestContext context) => Response(body: 'Hello'));

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app.call(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    final response = await http.get(Uri.parse('${server.url}/hi'));
    expect(response.body, equals('Not found, but ok'));
  });

  test('can call Router.routeNotFound.body() multiple times', () async {
    final b1 = await Router.routeNotFound.body();
    expect(b1, 'Route not found');
    final b2 = await Router.routeNotFound.body();
    expect(b2, b1);
  });

  test('can call Router.routeNotFound.bytes() multiple times', () async {
    final b1 = Router.routeNotFound.bytes();
    expect(b1, emits(utf8.encode('Route not found')));
    final b2 = Router.routeNotFound.bytes();
    expect(b2, emits(utf8.encode('Route not found')));
  });

  test('can call Router.routeNotFound.copyWith()', () async {
    final response = Router.routeNotFound.copyWith(headers: {'foo': 'bar'});
    expect(response.headers['foo'], equals('bar'));
    expect(response.body(), completion(equals('Route not found')));
  });

  test('can call Router.methodNotAllowed.body() multiple times', () async {
    final b1 = await Router.methodNotAllowed.body();
    expect(b1, 'Method not allowed');
    final b2 = await Router.methodNotAllowed.body();
    expect(b2, b1);
  });

  test('can call Router.methodNotAllowed.bytes() multiple times', () async {
    final b1 = Router.methodNotAllowed.bytes();
    expect(b1, emits(utf8.encode('Method not allowed')));
    final b2 = Router.methodNotAllowed.bytes();
    expect(b2, emits(utf8.encode('Method not allowed')));
  });

  test('can call Router.methodNotAllowed.copyWith()', () async {
    final response = Router.methodNotAllowed.copyWith(headers: {'foo': 'bar'});
    expect(response.headers['foo'], equals('bar'));
    expect(response.body(), completion(equals('Method not allowed')));
  });

  test('can mount route without params', () async {
    final context = _MockRequestContext();
    final app = Router()..mount('/', (RequestContext context) => Response());

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app.call(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    final response = await http.get(Uri.parse('${server.url}/'));
    expect(response.body, isEmpty);
    expect(response.statusCode, equals(HttpStatus.ok));
  });

  test('can mount dynamic route', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..mount('/api/v1/posts/<id>', (RequestContext context, String id) {
        return Response(body: '/api/v1/posts/$id');
      });
    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app.call(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    final response = await http.get(Uri.parse('${server.url}/api/v1/posts/42'));
    expect(response.body, equals('/api/v1/posts/42'));
  });

  test('can mount dynamic routes', () async {
    final context = _MockRequestContext();

    // Routes for <user> to <other>.
    // This gets nested parameters from previous mounts.
    Handler createUserToOtherHandler(String user, String other) {
      final router = Router()
        ..get('/<action>', (RequestContext context, String action) {
          return Response(body: '$user to $other: $action');
        });

      return router.call;
    }

    // Routes for a specific <user>.
    // The user value is extracted from the mount.
    Handler createUserHandler(String user) {
      final router = Router()
        ..mount('/to/<other>/', (RequestContext context, String other) {
          final handler = createUserToOtherHandler(user, other);
          return handler(context);
        })
        ..get('/self', (RequestContext context) {
          return Response(body: "I'm $user");
        })
        ..get('/', (RequestContext context) {
          return Response(body: '$user root');
        });
      return router.call;
    }

    final app = Router()
      ..get('/hello', (RequestContext context) {
        return Response(body: 'hello-world');
      })
      ..mount('/users/<user>', (RequestContext context, String user) {
        final handler = createUserHandler(user);
        return handler(context);
      })
      ..all('/<_|[^]*>', (RequestContext context) {
        return Response(body: 'catch-all-handler');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app.call(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    final helloResponse = await http.get(Uri.parse('${server.url}/hello'));
    expect(helloResponse.body, equals('hello-world'));

    final greetingResponse = await http.get(
      Uri.parse('${server.url}/users/dartfrog/to/dash/hi'),
    );
    expect(greetingResponse.body, equals('dartfrog to dash: hi'));

    final farewellResponse = await http.get(
      Uri.parse('${server.url}/users/dash/to/dartfrog/bye'),
    );
    expect(farewellResponse.body, equals('dash to dartfrog: bye'));

    final introResponse = await http.get(
      Uri.parse('${server.url}/users/dash/self'),
    );
    expect(introResponse.body, equals("I'm dash"));

    final rootResponse = await http.get(
      Uri.parse('${server.url}/users/dartfrog'),
    );
    expect(rootResponse.body, equals('dartfrog root'));

    final catchAllResponse = await http.get(
      Uri.parse('${server.url}/users/dartfrog/no-route'),
    );
    expect(catchAllResponse.body, equals('catch-all-handler'));
  });

  test('can mount dynamic routes with multiple parameters', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..mount(r'/first/<second>/third/<fourth|\d+>/last', (
        RequestContext context,
        String second,
        String fourthNum,
      ) {
        final router = Router()
          ..get('/', (r) => Response(body: '$second ${int.parse(fourthNum)}'));
        return router(context);
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app.call(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    final response = await http.get(
      Uri.parse('${server.url}/first/hello/third/42/last'),
    );
    expect(response.body, equals('hello 42'));
  });

  test('can mount dynamic routes with regexp', () async {
    final context = _MockRequestContext();
    final app = Router()
      ..mount(r'/before/<bookId|\d+>/after',
          (RequestContext context, String bookId) {
        final router = Router()
          ..get('/', (r) => Response(body: 'book ${int.parse(bookId)}'));
        return router(context);
      })
      ..all('/<_|[^]*>', (RequestContext context) {
        return Response(body: 'catch-all-handler');
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app.call(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    final bookResponse = await http.get(
      Uri.parse('${server.url}/before/42/after'),
    );
    expect(bookResponse.body, equals('book 42'));

    final catchAllResponse = await http.get(
      Uri.parse('${server.url}/before/abc/after'),
    );
    expect(catchAllResponse.body, equals('catch-all-handler'));
  });

  test('dynamic routes mountedParams', () async {
    final context = _MockRequestContext();

    final usersRouter = () {
      final router = Router();

      String getUser(RequestContext c) => c.mountedParams['user']!;

      router.get(
        '/self',
        (RequestContext context) => Response(body: "I'm ${getUser(context)}"),
      );
      return router;
    }();

    final app = Router()
      ..mount('/users/<user>', (
        RequestContext context,
        String user,
      ) {
        return usersRouter(context);
      });

    server.mount((request) async {
      when(() => context.request).thenReturn(
        Request(request.method, request.requestedUri),
      );
      final response = await app.call(context);
      final body = await response.body();
      return shelf.Response(response.statusCode, body: body);
    });

    final response = await http.get(
      Uri.parse('${server.url}/users/jack/self'),
    );
    expect(response.body, equals("I'm jack"));
  });

  group('RouterEntry', () {
    void testPattern(
      String pattern, {
      Map<String, Map<String, String>> match = const {},
      List<String> notMatch = const [],
    }) {
      group('RouterEntry: "$pattern"', () {
        final r = RouterEntry('GET', pattern, () => null);
        for (final e in match.entries) {
          test('Matches "${e.key}"', () {
            expect(r.match(e.key), equals(e.value));
          });
        }
        for (final v in notMatch) {
          test('NotMatch "$v"', () {
            expect(r.match(v), isNull);
          });
        }
      });
    }

    testPattern(
      '/hello',
      match: {'/hello': {}},
      notMatch: ['/not-hello', '/'],
    );

    testPattern(
      r'/user/<user>/groups/<group|\d+>',
      match: {
        '/user/felangel/groups/42': {
          'user': 'felangel',
          'group': '42',
        },
        '/user/felangel/groups/0': {
          'user': 'felangel',
          'group': '0',
        },
        '/user/123/groups/101': {
          'user': '123',
          'group': '101',
        },
      },
      notMatch: [
        '/user/',
        '/user/felangel/groups/5-3',
        '/user/felangel/test/groups/5',
        '/user/felangeltest/groups/4/',
        '/user/felangel/groups/',
        '/not-hello',
        '/',
      ],
    );

    test('non-capture regex only', () {
      expect(
        () => RouterEntry('GET', '/users/<user|([^]*)>/info', () {}),
        throwsA(anything),
      );
    });
  });

  group('RouterParams', () {
    test('returns empty params when none are found', () async {
      final request = _MockShelfRequest();
      when(() => request.context).thenReturn({});

      expect(request.params, isEmpty);
    });

    test('returns params when they are found', () async {
      const params = {'foo': 'bar'};
      final request = _MockShelfRequest();
      when(() => request.context).thenReturn({'shelf_router/params': params});

      expect(request.params, equals(params));
    });
  });
}
