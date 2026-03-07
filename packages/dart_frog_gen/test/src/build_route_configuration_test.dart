// Not needed for test file
// ignore_for_file: inference_failure_on_collection_literal

import 'dart:io';

import 'package:dart_frog_gen/src/build_route_configuration.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('buildRouteConfiguration', () {
    test('throws exception when routes directory does not exist', () {
      expect(() => buildRouteConfiguration(createTempDir()), throwsException);
    });

    test('excludes global middleware when it does not exist', () {
      final configuration = buildRouteConfiguration(
        createTempDir(directories: ['routes']),
      );
      expect(configuration.globalMiddleware, isNull);
    });

    test('serveStaticFiles is true when public directory exists', () {
      final configuration = buildRouteConfiguration(
        createTempDir(directories: ['routes', 'public']),
      );
      expect(configuration.serveStaticFiles, isTrue);
    });

    test('serveStaticFiles is false when public directory does not exist', () {
      final configuration = buildRouteConfiguration(
        createTempDir(directories: ['routes']),
      );
      expect(configuration.serveStaticFiles, isFalse);
    });

    test('invokeCustomEntrypoint is true when main.dart exists', () {
      final configuration = buildRouteConfiguration(
        createTempDir(
          directories: ['routes'],
          files: ['main.dart'],
        ),
      );
      expect(configuration.invokeCustomEntrypoint, isTrue);
    });

    test('invokeCustomEntrypoint is false when main.dart does not exist', () {
      final configuration = buildRouteConfiguration(
        createTempDir(directories: ['routes']),
      );
      expect(configuration.invokeCustomEntrypoint, isFalse);
    });

    test('invokeCustomInit is true when init exists in main.dart', () {
      final tempDirectory = createTempDir(
        directories: ['routes'],
        files: ['main.dart'],
      );

      File(path.join(tempDirectory.path, 'main.dart')).writeAsStringSync('''
Future<void> init(InternetAddress ip, int port) async {}
''');

      final configuration = buildRouteConfiguration(tempDirectory);
      expect(configuration.invokeCustomEntrypoint, isTrue);
    });

    test('invokeCustomInit is true when init with FutureOr exists in main.dart',
        () {
      final tempDirectory = createTempDir(
        directories: ['routes'],
        files: ['main.dart'],
      );

      File(path.join(tempDirectory.path, 'main.dart')).writeAsStringSync('''
FutureOr<void> init(InternetAddress ip, int port) async {}
''');

      final configuration = buildRouteConfiguration(tempDirectory);
      expect(configuration.invokeCustomEntrypoint, isTrue);
    });

    test(
        '''invokeCustomInit is true when init with different parameter names exists in main.dart''',
        () {
      final tempDirectory = createTempDir(
        directories: ['routes'],
        files: ['main.dart'],
      );

      File(path.join(tempDirectory.path, 'main.dart')).writeAsStringSync('''
Future<void> init(InternetAddress hello, int world) async {}
''');

      final configuration = buildRouteConfiguration(tempDirectory);
      expect(configuration.invokeCustomEntrypoint, isTrue);
    });

    test(
        '''invokeCustomInit is true when init with bad spacing exists in main.dart''',
        () {
      final tempDirectory = createTempDir(
        directories: ['routes'],
        files: ['main.dart'],
      );

      File(path.join(tempDirectory.path, 'main.dart')).writeAsStringSync('''
Future<void>init(InternetAddress ip,int port)async{}
''');

      final configuration = buildRouteConfiguration(tempDirectory);
      expect(configuration.invokeCustomEntrypoint, isTrue);
    });

    test('invokeCustomEntrypoint is false when main.dart does not exist', () {
      final configuration = buildRouteConfiguration(
        createTempDir(directories: ['routes']),
      );
      expect(configuration.invokeCustomInit, isFalse);
    });

    test('includes global middleware when it exists', () {
      final configuration = buildRouteConfiguration(
        createTempDir(files: ['routes/_middleware.dart']),
      );
      expect(configuration.globalMiddleware, isNotNull);
    });

    test('endpoint includes multiple routes when conflicts exist', () {
      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/users.dart',
            'routes/users/index.dart',
          ],
        ),
      );

      expect(
        configuration.endpoints,
        equals({
          '/users': [
            isARouteFile(path: '../routes/users.dart'),
            isARouteFile(path: '../routes/users/index.dart'),
          ],
        }),
      );
    });

    test('includes single index route', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'index',
              'path': '../routes/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(files: ['routes/index.dart']),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/': [isARouteFile(path: '../routes/index.dart')],
        }),
      );
    });

    test('includes multiple top-level routes', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'hello',
              'path': '../routes/hello.dart',
              'route': '/hello',
              'file_params': [],
              'wildcard': false,
            },
            {
              'name': 'index',
              'path': '../routes/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/index.dart',
            'routes/hello.dart',
          ],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/': [isARouteFile(path: '../routes/index.dart')],
          '/hello': [isARouteFile(path: '../routes/hello.dart')],
        }),
      );
    });

    test('includes nested routes', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'index',
              'path': '../routes/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': '_echo',
          'route': '/echo',
          'middleware': [],
          'files': [
            {
              'name': 'echo_message',
              'path': '../routes/echo/message.dart',
              'route': '/message',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/index.dart',
            'routes/echo/message.dart',
          ],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/': [isARouteFile(path: '../routes/index.dart')],
          '/echo/message': [isARouteFile(path: '../routes/echo/message.dart')],
        }),
      );
    });

    test('includes nested directories', () {
      const expected = [
        {
          'name': '_echo_message',
          'route': '/echo/message',
          'middleware': [],
          'files': [
            {
              'name': 'echo_message_index',
              'path': '../routes/echo/message/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: ['routes/echo/message/index.dart'],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/echo/message': [
            isARouteFile(path: '../routes/echo/message/index.dart'),
          ],
        }),
      );
    });

    test('includes dynamic route', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'index',
              'path': '../routes/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': '_echo',
          'route': '/echo',
          'middleware': [],
          'files': [
            {
              'name': r'echo_$message',
              'path': '../routes/echo/[message].dart',
              'route': '/<message>',
              'file_params': ['message'],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/index.dart',
            'routes/echo/[message].dart',
          ],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/': [
            isARouteFile(path: '../routes/index.dart'),
          ],
          '/echo/<message>': [
            isARouteFile(path: '../routes/echo/[message].dart'),
          ],
        }),
      );
    });

    test('includes dynamic nested directory routes', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'index',
              'path': '../routes/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': r'_$user',
          'route': '/<user>',
          'middleware': [],
          'files': [
            {
              'name': r'$user_$name',
              'path': '../routes/[user]/[name].dart',
              'route': '/<name>',
              'file_params': ['name'],
              'wildcard': false,
            }
          ],
          'directory_params': ['user'],
        },
        {
          'name': r'_$user_$id',
          'route': '/<user>/<id>',
          'middleware': [
            {
              'name': r'$user_$id__middleware',
              'path': '../routes/[user]/[id]/_middleware.dart',
            }
          ],
          'files': [
            {
              'name': r'$user_$id_index',
              'path': '../routes/[user]/[id]/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': ['user', 'id'],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/index.dart',
            'routes/[user]/[name].dart',
            'routes/[user]/[id]/index.dart',
            'routes/[user]/[id]/_middleware.dart',
          ],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/': [
            isARouteFile(path: '../routes/index.dart'),
          ],
          '/<user>/<name>': [
            isARouteFile(path: '../routes/[user]/[name].dart'),
          ],
          '/<user>/<id>': [
            isARouteFile(path: '../routes/[user]/[id]/index.dart'),
          ],
        }),
      );
    });

    test('includes dynamic nested directory routes w/cascading middleware', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'index',
              'path': '../routes/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': '_api',
          'route': '/api',
          'middleware': [],
          'files': [
            {
              'name': 'api_v1',
              'path': '../routes/api/v1.dart',
              'route': '/v1',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': r'_$user',
          'route': '/<user>',
          'middleware': [
            {
              'name': r'$user__middleware',
              'path': '../routes/[user]/_middleware.dart',
            }
          ],
          'files': [
            {
              'name': r'$user_$name',
              'path': '../routes/[user]/[name].dart',
              'route': '/<name>',
              'file_params': ['name'],
              'wildcard': false,
            }
          ],
          'directory_params': ['user'],
        },
        {
          'name': r'_$user_$id',
          'route': '/<user>/<id>',
          'middleware': [
            {
              'name': r'$user__middleware',
              'path': '../routes/[user]/_middleware.dart',
            },
            {
              'name': r'$user_$id__middleware',
              'path': '../routes/[user]/[id]/_middleware.dart',
            }
          ],
          'files': [
            {
              'name': r'$user_$id_index',
              'path': '../routes/[user]/[id]/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': ['user', 'id'],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/index.dart',
            'routes/api/v1.dart',
            'routes/[user]/_middleware.dart',
            'routes/[user]/[name].dart',
            'routes/[user]/[id]/index.dart',
            'routes/[user]/[id]/_middleware.dart',
          ],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/': [
            isARouteFile(path: '../routes/index.dart'),
          ],
          '/api/v1': [
            isARouteFile(path: '../routes/api/v1.dart'),
          ],
          '/<user>/<name>': [
            isARouteFile(path: '../routes/[user]/[name].dart'),
          ],
          '/<user>/<id>': [
            isARouteFile(path: '../routes/[user]/[id]/index.dart'),
          ],
        }),
      );
    });

    test('supports /[id]/api/index.dart', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'index',
              'path': '../routes/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': r'_$id_api',
          'route': '/<id>/api',
          'middleware': [],
          'files': [
            {
              'name': r'$id_api_index',
              'path': '../routes/[id]/api/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': ['id'],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/index.dart',
            'routes/[id]/api/index.dart',
          ],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/': [isARouteFile(path: '../routes/index.dart')],
          '/<id>/api': [isARouteFile(path: '../routes/[id]/api/index.dart')],
        }),
      );
    });

    test('supports /[id]/api/test.dart', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'index',
              'path': '../routes/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': r'_$id_api',
          'route': '/<id>/api',
          'middleware': [],
          'files': [
            {
              'name': r'$id_api_test',
              'path': '../routes/[id]/api/test.dart',
              'route': '/test',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': ['id'],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/index.dart',
            'routes/[id]/api/test.dart',
          ],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/': [
            isARouteFile(path: '../routes/index.dart'),
          ],
          '/<id>/api/test': [
            isARouteFile(path: '../routes/[id]/api/test.dart'),
          ],
        }),
      );
    });

    test('supports /[id]/api/[name]/index.dart', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'index',
              'path': '../routes/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': r'_$id_api_$name',
          'route': '/<id>/api/<name>',
          'middleware': [],
          'files': [
            {
              'name': r'$id_api_$name_index',
              'path': '../routes/[id]/api/[name]/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': ['id', 'name'],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/index.dart',
            'routes/[id]/api/[name]/index.dart',
          ],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/': [
            isARouteFile(path: '../routes/index.dart'),
          ],
          '/<id>/api/<name>': [
            isARouteFile(path: '../routes/[id]/api/[name]/index.dart'),
          ],
        }),
      );
    });

    test('supports /[id]/api/[name]/test.dart', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'index',
              'path': '../routes/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': r'_$id_api_$name',
          'route': '/<id>/api/<name>',
          'middleware': [],
          'files': [
            {
              'name': r'$id_api_$name_test',
              'path': '../routes/[id]/api/[name]/test.dart',
              'route': '/test',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': ['id', 'name'],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/index.dart',
            'routes/[id]/api/[name]/test.dart',
          ],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/': [
            isARouteFile(path: '../routes/index.dart'),
          ],
          '/<id>/api/<name>/test': [
            isARouteFile(path: '../routes/[id]/api/[name]/test.dart'),
          ],
        }),
      );
    });

    test('supports /api/api.dart', () {
      const expected = [
        {
          'name': '_api',
          'route': '/api',
          'middleware': [],
          'files': [
            {
              'name': 'api_api',
              'path': '../routes/api/api.dart',
              'route': '/api',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: ['routes/api/api.dart'],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/api/api': [isARouteFile(path: '../routes/api/api.dart')],
        }),
      );
    });

    test('supports /[a]_[b].dart', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': r'$a_$b',
              'path': '../routes/[a]_[b].dart',
              'route': '/<a>_<b>',
              'file_params': ['a', 'b'],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: ['routes/[a]_[b].dart'],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/<a>_<b>': [isARouteFile(path: '../routes/[a]_[b].dart')],
        }),
      );
    });

    test('supports /[a]_[b]/index.dart', () {
      const expected = [
        {
          'name': r'_$a_$b',
          'route': '/<a>_<b>',
          'middleware': [],
          'files': [
            {
              'name': r'$a_$b_index',
              'path': '../routes/[a]_[b]/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': ['a', 'b'],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: ['routes/[a]_[b]/index.dart'],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/<a>_<b>': [isARouteFile(path: '../routes/[a]_[b]/index.dart')],
        }),
      );
    });

    test('supports /a_[b].dart', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': r'a_$b',
              'path': '../routes/a_[b].dart',
              'route': '/a_<b>',
              'file_params': ['b'],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: ['routes/a_[b].dart'],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/a_<b>': [isARouteFile(path: '../routes/a_[b].dart')],
        }),
      );
    });

    test('supports /a_[b]_c.dart', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': r'a_$b_c',
              'path': '../routes/a_[b]_c.dart',
              'route': '/a_<b>_c',
              'file_params': ['b'],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: ['routes/a_[b]_c.dart'],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/a_<b>_c': [isARouteFile(path: '../routes/a_[b]_c.dart')],
        }),
      );
    });

    test('supports /[a]-[b].dart', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': r'$a-$b',
              'path': '../routes/[a]-[b].dart',
              'route': '/<a>-<b>',
              'file_params': ['a', 'b'],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: ['routes/[a]-[b].dart'],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/<a>-<b>': [isARouteFile(path: '../routes/[a]-[b].dart')],
        }),
      );
    });

    test('detects rogue routes.', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'api',
              'path': '../routes/api.dart',
              'route': '/api',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': '_api',
          'route': '/api',
          'middleware': [],
          'files': [
            {
              'name': 'api_v1',
              'path': '../routes/api/v1.dart',
              'route': '/v1',
              'file_params': [],
              'wildcard': false,
            },
            {
              'name': r'api_$id',
              'path': '../routes/api/[id].dart',
              'route': '/<id>',
              'file_params': ['id'],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': '_api_v1',
          'route': '/api/v1',
          'middleware': [],
          'files': [
            {
              'name': 'api_v1_hello',
              'path': '../routes/api/v1/hello.dart',
              'route': '/hello',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/api.dart',
            'routes/api/[id].dart',
            'routes/api/v1.dart',
            'routes/api/v1/hello.dart',
          ],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/api': [
            isA<RouteFile>().having(
              (r) => r.path,
              'path',
              '../routes/api.dart',
            ),
          ],
          '/api/v1': [
            isA<RouteFile>().having(
              (r) => r.path,
              'path',
              '../routes/api/v1.dart',
            ),
          ],
          '/api/<id>': [
            isA<RouteFile>().having(
              (r) => r.path,
              'path',
              '../routes/api/[id].dart',
            ),
          ],
          '/api/v1/hello': [
            isA<RouteFile>().having(
              (r) => r.path,
              'path',
              '../routes/api/v1/hello.dart',
            ),
          ],
        }),
      );
      expect(
        configuration.rogueRoutes,
        equals([
          isA<RouteFile>().having(
            (r) => r.path,
            'path',
            '../routes/api.dart',
          ),
          isA<RouteFile>().having(
            (r) => r.path,
            'path',
            '../routes/api/v1.dart',
          ),
        ]),
      );
    });

    test('does not report rogue route when index.dart already exists', () {
      const expected = [
        {
          'name': '_',
          'route': '/',
          'middleware': [],
          'files': [
            {
              'name': 'api',
              'path': '../routes/api.dart',
              'route': '/api',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        },
        {
          'name': '_api',
          'route': '/api',
          'middleware': [],
          'files': [
            {
              'name': 'api_index',
              'path': '../routes/api/index.dart',
              'route': '/',
              'file_params': [],
              'wildcard': false,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/api.dart',
            'routes/api/index.dart',
          ],
        ),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/api': [
            isA<RouteFile>().having(
              (r) => r.path,
              'path',
              '../routes/api.dart',
            ),
            isA<RouteFile>().having(
              (r) => r.path,
              'path',
              '../routes/api/index.dart',
            ),
          ],
        }),
      );
      expect(configuration.rogueRoutes, isEmpty);
    });

    test('includes wildcard routes', () {
      const expected = [
        {
          'name': '_test',
          'route': '/test',
          'middleware': [],
          'files': [
            {
              'name': r'test_$wildcard_value',
              'path': '../routes/test/[...value].dart',
              'route': '/',
              'file_params': ['value'],
              'wildcard': true,
            }
          ],
          'directory_params': [],
        }
      ];

      final configuration = buildRouteConfiguration(
        createTempDir(files: ['routes/test/[...value].dart']),
      );

      expect(
        configuration.directories.map((d) => d.toJson()).toList(),
        equals(expected),
      );
      expect(
        configuration.endpoints,
        equals({
          '/test': [isARouteFile(path: '../routes/test/[...value].dart')],
        }),
      );
    });

    test('throws when a folder is mapped to a wildcard', () {
      expect(
        () => buildRouteConfiguration(
          createTempDir(files: ['routes/[...value]/index.dart']),
        ),
        throwsArgumentError,
      );
    });

    test('isWildcard returns correctly', () {
      expect('/blog/[...slug].dart'.isWildcard(), isTrue);
      expect('/blog/content/[...slug].dart'.isWildcard(), isTrue);
      expect('/blog/content/[slug].dart'.isWildcard(), isFalse);
      expect('/[...value]'.isWildcard(), isTrue);

      expect(
        '/blog/content/[...slug].dart'.toParams(),
        equals(
          ['slug'],
        ),
      );
    });

    test(
        'orders by wildcard, then total segments '
        'when specificity is equal', () {
      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/x/index.dart',
            'routes/x/[id].dart',
            'routes/x/[...rest].dart',
          ],
        ),
      );

      final xDir = configuration.directories.firstWhere((d) => d.route == '/x');
      final fileRoutes = xDir.files.map((f) => f.route).toList();

      expect(fileRoutes, equals(['/<id>', '/', '/']));
      expect(xDir.files.last.wildcard, isTrue);
    });

    test(
        'uses route string as deterministic '
        'fallback when specificity is equal', () {
      final configuration = buildRouteConfiguration(
        createTempDir(
          files: [
            'routes/x/a.dart',
            'routes/x/b.dart',
          ],
        ),
      );

      final xDir = configuration.directories.firstWhere((d) => d.route == '/x');
      final fileRoutes = xDir.files.map((f) => f.route).toList();

      expect(fileRoutes, equals(['/a', '/b']));
    });
  });

  group('RouteConfiguration', () {
    test('toJson transforms everything into json', () {
      const configuration = RouteConfiguration(
        globalMiddleware: MiddlewareFile(
          name: 'middleware',
          path: '../routes/_middleware.dart',
        ),
        middleware: [
          MiddlewareFile(
            name: 'middleware',
            path: '../routes/_middleware.dart',
          ),
          MiddlewareFile(
            name: r'$id__middleware',
            path: '../routes/[id]/_middleware.dart',
          ),
        ],
        directories: [
          RouteDirectory(
            name: '_',
            route: '/',
            middleware: [],
            files: [],
            params: [],
          ),
          RouteDirectory(
            name: r'_$id',
            route: '/<id>',
            middleware: [],
            files: [],
            params: [],
          ),
          RouteDirectory(
            name: r'_$id_existing_as_directory',
            route: '/<id>/existing_as_dir',
            files: [],
            middleware: [],
            params: [],
          ),
        ],
        routes: [
          RouteFile(
            name: 'index',
            path: '../routes/index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
          RouteFile(
            name: r'$id_existing_as_file',
            path: '../routes/[id]/existing_as_file.dart',
            route: '/existing_as_file',
            params: [],
            wildcard: false,
          ),
          RouteFile(
            name: r'$id_existing_as_dir_index',
            path: '../routes/[id]/existing_as_dir/index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
        endpoints: {
          '/': <RouteFile>[
            RouteFile(
              name: 'index',
              path: '../routes/index.dart',
              route: '/',
              params: [],
              wildcard: false,
            ),
          ],
          '/<id>/existing_as_file': <RouteFile>[
            RouteFile(
              name: r'$id_existing_as_file',
              path: '../routes/[id]/existing_as_file.dart',
              route: '/existing_as_file',
              params: [],
              wildcard: false,
            ),
          ],
          '/<id>/existing_as_dir': <RouteFile>[
            RouteFile(
              name: r'$id_existing_as_dir_index',
              path: '../routes/[id]/existing_as_dir/index.dart',
              route: '/',
              params: [],
              wildcard: false,
            ),
          ],
        },
        rogueRoutes: [],
        serveStaticFiles: true,
      );

      expect(
        configuration.toJson(),
        equals(
          {
            'invokeCustomEntrypoint': false,
            'invokeCustomInit': false,
            'serveStaticFiles': true,
            'globalMiddleware': {
              'name': 'middleware',
              'path': '../routes/_middleware.dart',
            },
            'middleware': [
              {'name': 'middleware', 'path': '../routes/_middleware.dart'},
              {
                'name': r'$id__middleware',
                'path': '../routes/[id]/_middleware.dart',
              }
            ],
            'directories': [
              {
                'name': '_',
                'route': '/',
                'middleware': [],
                'files': [],
                'directory_params': [],
              },
              {
                'name': r'_$id',
                'route': '/<id>',
                'middleware': [],
                'files': [],
                'directory_params': [],
              },
              {
                'name': r'_$id_existing_as_directory',
                'route': '/<id>/existing_as_dir',
                'middleware': [],
                'files': [],
                'directory_params': [],
              }
            ],
            'routes': [
              {
                'name': 'index',
                'path': '../routes/index.dart',
                'route': '/',
                'file_params': [],
                'wildcard': false,
              },
              {
                'name': r'$id_existing_as_file',
                'path': '../routes/[id]/existing_as_file.dart',
                'route': '/existing_as_file',
                'file_params': [],
                'wildcard': false,
              },
              {
                'name': r'$id_existing_as_dir_index',
                'path': '../routes/[id]/existing_as_dir/index.dart',
                'route': '/',
                'file_params': [],
                'wildcard': false,
              }
            ],
            'endpoints': {
              '/': [
                {
                  'name': 'index',
                  'path': '../routes/index.dart',
                  'route': '/',
                  'file_params': [],
                  'wildcard': false,
                }
              ],
              '/<id>/existing_as_file': [
                {
                  'name': r'$id_existing_as_file',
                  'path': '../routes/[id]/existing_as_file.dart',
                  'route': '/existing_as_file',
                  'file_params': [],
                  'wildcard': false,
                }
              ],
              '/<id>/existing_as_dir': [
                {
                  'name': r'$id_existing_as_dir_index',
                  'path': '../routes/[id]/existing_as_dir/index.dart',
                  'route': '/',
                  'file_params': [],
                  'wildcard': false,
                }
              ],
            },
            'rogueRoutes': [],
          },
        ),
      );
    });
  });
}

Directory createTempDir({
  List<String> directories = const [],
  List<String> files = const [],
}) {
  final tempDir = Directory.systemTemp.createTempSync();
  for (final directory in directories) {
    Directory(path.join(tempDir.path, directory)).createSync(recursive: true);
  }
  for (final f in files) {
    File(path.join(tempDir.path, f)).createSync(recursive: true);
  }
  return tempDir;
}

Matcher isARouteFile({required String path}) {
  return isA<RouteFile>().having((r) => r.path, 'path', path);
}
