import 'package:dart_frog_gen/dart_frog_gen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockRouteConfiguration extends Mock implements RouteConfiguration {}

void main() {
  group('reportRouteConflicts', () {
    late RouteConfiguration configuration;

    late bool violationStartCalled;
    late bool violationEndCalled;
    late List<String> conflicts;

    setUp(() {
      configuration = _MockRouteConfiguration();

      violationStartCalled = false;
      violationEndCalled = false;
      conflicts = [];
    });

    test('reports nothing when there are no endpoints', () {
      when(() => configuration.endpoints).thenReturn({});

      reportRouteConflicts(
        configuration,
        onViolationStart: () {
          violationStartCalled = true;
        },
        onRouteConflict: (_, __, conflictingEndpoint) {
          conflicts.add(conflictingEndpoint);
        },
        onViolationEnd: () {
          violationEndCalled = true;
        },
      );

      expect(violationStartCalled, isFalse);
      expect(violationEndCalled, isFalse);
      expect(conflicts, isEmpty);
    });

    test('reports nothing when there are endpoints and no conflicts', () {
      when(() => configuration.endpoints).thenReturn({
        '/': const [
          RouteFile(
            name: 'index',
            path: 'index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
        '/hello': const [
          RouteFile(
            name: 'hello',
            path: 'hello.dart',
            route: '/hello',
            params: [],
            wildcard: false,
          ),
        ],
      });

      reportRouteConflicts(
        configuration,
        onViolationStart: () {
          violationStartCalled = true;
        },
        onRouteConflict: (_, __, conflictingEndpoint) {
          conflicts.add(conflictingEndpoint);
        },
        onViolationEnd: () {
          violationEndCalled = true;
        },
      );

      expect(violationStartCalled, isFalse);
      expect(violationEndCalled, isFalse);
      expect(conflicts, isEmpty);
    });

    test('reports single conflict when there is one endpoint with conflicts',
        () {
      when(() => configuration.endpoints).thenReturn({
        '/': const [
          RouteFile(
            name: 'index',
            path: 'index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
        '/hello': const [
          RouteFile(
            name: 'hello',
            path: 'hello.dart',
            route: '/hello',
            params: [],
            wildcard: false,
          ),
          RouteFile(
            name: 'hello_index',
            path: 'hello/index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
      });

      reportRouteConflicts(
        configuration,
        onViolationStart: () {
          violationStartCalled = true;
        },
        onRouteConflict: (_, __, conflictingEndpoint) {
          conflicts.add(conflictingEndpoint);
        },
        onViolationEnd: () {
          violationEndCalled = true;
        },
      );

      expect(violationStartCalled, isTrue);
      expect(violationEndCalled, isTrue);
      expect(conflicts, ['/hello']);
    });

    test(
        'reports multiple conflicts '
        'when there are multiple endpoint with conflicts', () {
      when(() => configuration.endpoints).thenReturn({
        '/': const [
          RouteFile(
            name: 'index',
            path: 'index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
        '/hello': const [
          RouteFile(
            name: 'hello',
            path: 'hello.dart',
            route: '/hello',
            params: [],
            wildcard: false,
          ),
          RouteFile(
            name: 'hello_index',
            path: 'hello/index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
        '/echo': const [
          RouteFile(
            name: 'echo',
            path: 'echo.dart',
            route: '/echo',
            params: [],
            wildcard: false,
          ),
          RouteFile(
            name: 'echo_index',
            path: 'echo/index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
      });

      reportRouteConflicts(
        configuration,
        onViolationStart: () {
          violationStartCalled = true;
        },
        onRouteConflict: (_, __, conflictingEndpoint) {
          conflicts.add(conflictingEndpoint);
        },
        onViolationEnd: () {
          violationEndCalled = true;
        },
      );

      expect(violationStartCalled, isTrue);
      expect(violationEndCalled, isTrue);
      expect(conflicts, ['/hello', '/echo']);
    });

    test(
      'does not report error when static route can take precedence over '
      'a dynamic route (e.g. /cars/mine vs /cars/<id>)',
      () {
        when(() => configuration.endpoints).thenReturn({
          '/cars/<id>': const [
            RouteFile(
              name: r'cars_$id_index',
              path: '../routes/cars/[id]/index.dart',
              route: '/cars/<id>',
              params: [],
              wildcard: false,
            ),
          ],
          '/cars/mine': const [
            RouteFile(
              name: 'cars_mine',
              path: '../routes/cars/mine.dart',
              route: '/cars/mine',
              params: [],
              wildcard: false,
            ),
          ],
        });

        reportRouteConflicts(
          configuration,
          onViolationStart: () {
            violationStartCalled = true;
          },
          onRouteConflict: (
            originalFilePath,
            conflictingFilePath,
            conflictingEndpoint,
          ) {
            conflicts.add('$originalFilePath and '
                '$conflictingFilePath -> '
                '$conflictingEndpoint');
          },
          onViolationEnd: () {
            violationEndCalled = true;
          },
        );

        expect(violationStartCalled, isFalse);
        expect(violationEndCalled, isFalse);
        expect(conflicts, isEmpty);
      },
    );

    test(
      'does not report error when multiple static routes can take precedence '
      'over dynamic routes at different nesting levels',
      () {
        when(() => configuration.endpoints).thenReturn({
          '/turtles/random': const [
            RouteFile(
              name: 'turtles_random',
              path: '../routes/turtles/random.dart',
              route: '/turtles/random',
              params: [],
              wildcard: false,
            ),
          ],
          '/turtles/<id>': const [
            RouteFile(
              name: r'turtles_$id_index',
              path: '../routes/turtles/[id]/index.dart',
              route: '/turtles/<id>',
              params: [],
              wildcard: false,
            ),
          ],
          '/turtles/<id>/bla': const [
            RouteFile(
              name: r'turtles_$id_bla',
              path: '../routes/turtles/[id]/bla.dart',
              route: '/turtles/<id>/bla',
              params: [],
              wildcard: false,
            ),
          ],
          '/turtles/<id>/<name>': const [
            RouteFile(
              name: r'turtles_$id_$name_index',
              path: '../routes/turtles/[id]/[name]/index.dart',
              route: '/turtles/<id>/<name>',
              params: [],
              wildcard: false,
            ),
          ],
          '/turtles/<id>/<name>/ble.dart': const [
            RouteFile(
              name: r'turtles_$id_$name_ble.dart',
              path: '../routes/turtles/[id]/[name]/ble.dart',
              route: '/turtles/<id>/<name>/ble.dart',
              params: [],
              wildcard: false,
            ),
          ],
        });

        reportRouteConflicts(
          configuration,
          onViolationStart: () {
            violationStartCalled = true;
          },
          onRouteConflict: (
            originalFilePath,
            conflictingFilePath,
            conflictingEndpoint,
          ) {
            conflicts.add(
              '$originalFilePath and '
              '$conflictingFilePath -> '
              '$conflictingEndpoint',
            );
          },
          onViolationEnd: () {
            violationEndCalled = true;
          },
        );

        expect(violationStartCalled, isFalse);
        expect(violationEndCalled, isFalse);
        expect(conflicts, isEmpty);
      },
    );

    test(
      'reports error when overlap is ambiguous',
      () {
        when(() => configuration.endpoints).thenReturn({
          '/a/<foo>': const [
            RouteFile(
              name: r'a_$foo',
              path: '../routes/a/[foo].dart',
              route: '/a/<foo>',
              params: [],
              wildcard: false,
            ),
          ],
          '/a/<bar>': const [
            RouteFile(
              name: r'a_$bar',
              path: '../routes/a/[bar].dart',
              route: '/a/<bar>',
              params: [],
              wildcard: false,
            ),
          ],
        });

        reportRouteConflicts(
          configuration,
          onViolationStart: () {
            violationStartCalled = true;
          },
          onRouteConflict: (
            originalFilePath,
            conflictingFilePath,
            conflictingEndpoint,
          ) {
            conflicts.add('$originalFilePath and '
                '$conflictingFilePath -> '
                '$conflictingEndpoint');
          },
          onViolationEnd: () {
            violationEndCalled = true;
          },
        );

        expect(violationStartCalled, isTrue);
        expect(violationEndCalled, isTrue);
        expect(
          conflicts,
          equals(
            [
              '${path.normalize('/a/<bar>')} and ${path.normalize('/a/<foo>')} -> /a/<bar>',
              '${path.normalize('/a/<foo>')} and ${path.normalize('/a/<bar>')} -> /a/<foo>',
            ],
          ),
        );
      },
    );

    test(
      'does not report error when a static route can take precedence over '
      'a wildcard route (e.g. /files/latest vs /files/*)',
      () {
        when(() => configuration.endpoints).thenReturn({
          '/files/*': const [
            RouteFile(
              name: r'files_$wildcard',
              path: '../routes/files/[...].dart',
              route: '/files/*',
              params: [],
              wildcard: true,
            ),
          ],
          '/files/latest': const [
            RouteFile(
              name: 'files_latest',
              path: '../routes/files/latest.dart',
              route: '/files/latest',
              params: [],
              wildcard: false,
            ),
          ],
        });

        reportRouteConflicts(
          configuration,
          onViolationStart: () => violationStartCalled = true,
          onRouteConflict: (a, b, endpoint) =>
              conflicts.add('$a and $b -> $endpoint'),
          onViolationEnd: () => violationEndCalled = true,
        );

        expect(violationStartCalled, isFalse);
        expect(violationEndCalled, isFalse);
        expect(conflicts, isEmpty);
      },
    );

    test(
      'does not report conflict when dynamic route overlaps wildcard route',
      () {
        when(() => configuration.endpoints).thenReturn({
          '/files/*': const [
            RouteFile(
              name: 'filesWildcard',
              path: '',
              route: '/files/*',
              params: [],
              wildcard: true,
            ),
          ],
          '/files/<id>': const [
            RouteFile(
              name: 'filesId',
              path: '',
              route: '/files/<id>',
              params: ['id'],
              wildcard: false,
            ),
          ],
        });

        reportRouteConflicts(
          configuration,
          onViolationStart: () => violationStartCalled = true,
          onRouteConflict: (original, conflicting, endpoint) {
            conflicts.add('$original and $conflicting -> $endpoint');
          },
          onViolationEnd: () => violationEndCalled = true,
        );

        expect(violationStartCalled, isFalse);
        expect(violationEndCalled, isFalse);
        expect(conflicts, isEmpty);
      },
    );
  });
}
