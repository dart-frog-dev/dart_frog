import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'helpers/helpers.dart';

/// Objectives:
///
/// * Generate a new Dart Frog project via `dart_frog create`
/// * Generate a new route via `dart_frog new route`
/// * Generate a new middleware via `dart_frog new middleware`
void main() {
  final String slash;
  final isWindowsStyle = path.Style.platform == path.Style.windows;
  if (isWindowsStyle) {
    slash = r'\';
  } else {
    slash = '/';
  }

  const projectName = 'example';
  final tempDirectory = Directory.systemTemp.createTempSync();
  final projectDirectory = Directory(
    path.join(tempDirectory.path, projectName),
  );

  final routesDirectory = Directory(path.join(projectDirectory.path, 'routes'));

  setUpAll(() async {
    await dartFrogCreate(projectName: projectName, directory: tempDirectory);
  });

  tearDownAll(() async {
    await tempDirectory.delete(recursive: true);
  });

  group('dart_frog new route', () {
    test('Creates route', () async {
      await dartFrogNewRoute('/new_route', directory: projectDirectory);

      expect(fileAt('new_route.dart', on: routesDirectory), exists);
    });

    test('Creates route without the leading slash', () async {
      await dartFrogNewRoute('another_new_route', directory: projectDirectory);

      expect(fileAt('another_new_route.dart', on: routesDirectory), exists);
    });

    test(skip: true, 'Creates dynamic route', () async {
      await dartFrogNewRoute('/[id]', directory: projectDirectory);

      expect(fileAt('[id].dart', on: routesDirectory), exists);
    });

    test('Creates nested dynamic route', () async {
      await dartFrogNewRoute('/inn/[id]/route', directory: projectDirectory);

      expect(fileAt('inn/[id]/route.dart', on: routesDirectory), exists);
    });

    test('Creates a index route for an existing directory', () async {
      Directory(
        path.join(routesDirectory.path, 'nested'),
      ).createSync(recursive: true);

      await dartFrogNewRoute('/nested', directory: projectDirectory);

      expect(fileAt('nested/index.dart', on: routesDirectory), exists);
    });

    test('Avoid rogue routes', () async {
      await dartFrogNewRoute('/some_route', directory: projectDirectory);

      expect(fileAt('some_route.dart', on: routesDirectory), exists);

      await dartFrogNewRoute(
        '/some_route/internal',
        directory: projectDirectory,
      );

      expect(fileAt('some_route.dart', on: routesDirectory), doesNotExist);
      expect(fileAt('some_route/index.dart', on: routesDirectory), exists);
      expect(fileAt('some_route/internal.dart', on: routesDirectory), exists);
    });

    test('Avoid rogue routes (nested)', () async {
      await dartFrogNewRoute('/some_other_route', directory: projectDirectory);

      expect(fileAt('some_other_route.dart', on: routesDirectory), exists);

      await dartFrogNewRoute(
        '/some_other_route/deep/deep/internal',
        directory: projectDirectory,
      );

      expect(
        fileAt('some_other_route.dart', on: routesDirectory),
        doesNotExist,
      );
      expect(
        fileAt('some_other_route/index.dart', on: routesDirectory),
        exists,
      );
      expect(
        fileAt('some_other_route/deep/deep/internal.dart', on: routesDirectory),
        exists,
      );
    });

    test('Creates route normally when there is a non-dart file with the same '
        'route path', () async {
      File(
        path.join(routesDirectory.path, 'something.py'),
      ).createSync(recursive: true);

      await dartFrogNewRoute('/something', directory: projectDirectory);

      expect(fileAt('something.dart', on: routesDirectory), exists);
      expect(fileAt('something.py', on: routesDirectory), exists);
    });

    test('Excuse root route', () async {
      await expectLater(
        () async => dartFrogNewRoute('/', directory: projectDirectory),
        failsWith(stderr: 'Failed to create route: / already exists.'),
      );
    });

    test('Excuse existing endpoints', () async {
      await dartFrogNewRoute('/existing_endpoint', directory: projectDirectory);

      await expectLater(
        () async =>
            dartFrogNewRoute('/existing_endpoint', directory: projectDirectory),
        failsWith(
          stderr: 'Failed to create route: /existing_endpoint already exists.',
        ),
      );
    });

    test('Excuse existing endpoints (indexed route)', () async {
      await dartFrogNewRoute(
        '/existing_endpoint_dir',
        directory: projectDirectory,
      );

      await dartFrogNewRoute(
        '/existing_endpoint_dir/inside',
        directory: projectDirectory,
      );

      await expectLater(
        () async => dartFrogNewRoute(
          '/existing_endpoint_dir',
          directory: projectDirectory,
        ),
        failsWith(
          stderr:
              'Failed to create route: /existing_endpoint_dir already exists.',
        ),
      );
    });

    test('Excuse route creation of invalid route identifiers', () async {
      await expectLater(
        () async => dartFrogNewRoute('/👯‍', directory: projectDirectory),
        failsWith(stderr: 'Route path segments must be valid Dart identifiers'),
      );
    });

    test('Excuse route creation of doubled route params', () async {
      await expectLater(
        () async => dartFrogNewRoute(
          '/[id]/something/[id]',
          directory: projectDirectory,
        ),
        failsWith(
          stderr: 'Failed to create route: Duplicate parameter name found: id',
        ),
      );
    });

    group('Invalid states', () {
      // These tests create invalid states that may break other tests if
      // running in parallel on shared files.
      const projectName = 'error_project';

      late Directory testDirectory;
      late Directory routesDirectory;
      late Directory projectDirectory;
      setUp(() async {
        testDirectory = tempDirectory.createTempSync(projectName);
        await dartFrogCreate(
          projectName: projectName,
          directory: testDirectory,
        );

        projectDirectory = Directory(
          path.join(testDirectory.path, projectName),
        );

        routesDirectory = Directory(path.join(projectDirectory.path, 'routes'));
      });

      tearDown(() async {
        await projectDirectory.delete(recursive: true);
      });

      test('Excuse existing endpoints (existing rogue route)', () async {
        await dartFrogNewRoute('/existing_rogue', directory: projectDirectory);

        Directory(
          path.join(routesDirectory.path, 'existing_rogue'),
        ).createSync(recursive: true);

        await expectLater(
          () =>
              dartFrogNewRoute('/existing_rogue', directory: projectDirectory),
          failsWith(
            stderr:
                'Failed to create route: Rogue route detected. '
                'Rename routes${slash}existing_rogue.dart to '
                'routes${slash}existing_rogue${slash}index.dart.',
          ),
        );
      });

      test('Excuse route creation upon existing route conflicts', () async {
        await dartFrogNewRoute(
          '/conflicting_route',
          directory: projectDirectory,
        );

        File(
          path.join(routesDirectory.path, 'conflicting_route/index.dart'),
        ).createSync(recursive: true);

        await expectLater(
          () async => dartFrogNewRoute(
            '/conflicting_route',
            directory: projectDirectory,
          ),
          failsWith(
            stderr:
                'Failed to create route: '
                'Route conflict detected. '
                'routes${slash}conflicting_route.dart and '
                'routes${slash}conflicting_route${slash}index.dart '
                'both resolve to /conflicting_route.',
          ),
        );
      });
    });
  });

  group('dart_frog new middleware', () {
    test('Creates global middleware', () async {
      await dartFrogNewMiddleware('/', directory: projectDirectory);

      expect(fileAt('_middleware.dart', on: routesDirectory), exists);
    });

    test('Creates middleware', () async {
      await dartFrogNewMiddleware('/new_route', directory: projectDirectory);

      expect(fileAt('new_route/_middleware.dart', on: routesDirectory), exists);
    });

    test('Creates middleware without the leading slash', () async {
      await dartFrogNewMiddleware(
        'another_new_route',
        directory: projectDirectory,
      );

      expect(
        fileAt('another_new_route/_middleware.dart', on: routesDirectory),
        exists,
      );
    });

    test('Creates middleware in dynamic route', () async {
      await dartFrogNewMiddleware('/[id]', directory: projectDirectory);

      expect(fileAt('[id]/_middleware.dart', on: routesDirectory), exists);
    });

    test('Creates middleware in nested dynamic route', () async {
      await dartFrogNewMiddleware(
        '/inn/[id]/route',
        directory: projectDirectory,
      );

      expect(
        fileAt('inn/[id]/route/_middleware.dart', on: routesDirectory),
        exists,
      );
    });

    test('Creates middleware in existing file route', () async {
      await dartFrogNewRoute(
        '/existing_file_route',
        directory: projectDirectory,
      );

      expect(fileAt('existing_file_route.dart', on: routesDirectory), exists);

      await dartFrogNewMiddleware(
        '/existing_file_route',
        directory: projectDirectory,
      );

      expect(
        fileAt('existing_file_route.dart', on: routesDirectory),
        doesNotExist,
      );

      expect(
        fileAt('existing_file_route/index.dart', on: routesDirectory),
        exists,
      );

      expect(
        fileAt('existing_file_route/_middleware.dart', on: routesDirectory),
        exists,
      );
    });

    test('Creates middleware in existing dynamic route', () async {
      await dartFrogNewRoute(
        '/prefix/[existing_dynamic_route]',
        directory: projectDirectory,
      );

      expect(
        fileAt('prefix/[existing_dynamic_route].dart', on: routesDirectory),
        exists,
      );

      await dartFrogNewMiddleware(
        '/prefix/[existing_dynamic_route]',
        directory: projectDirectory,
      );

      expect(
        fileAt('prefix/[existing_dynamic_route].dart', on: routesDirectory),
        doesNotExist,
      );

      expect(
        fileAt(
          'prefix/[existing_dynamic_route]/index.dart',
          on: routesDirectory,
        ),
        exists,
      );

      expect(
        fileAt(
          'prefix/[existing_dynamic_route]/_middleware.dart',
          on: routesDirectory,
        ),
        exists,
      );
    });

    test('Excuse existing middlewares', () async {
      await dartFrogNewMiddleware(
        '/existing_middleware',
        directory: projectDirectory,
      );

      await expectLater(
        () async => dartFrogNewMiddleware(
          '/existing_middleware',
          directory: projectDirectory,
        ),
        failsWith(
          stderr:
              'There is already a middleware at '
              'routes${slash}existing_middleware${slash}_middleware.dart',
        ),
      );
    });

    test('Excuse middleware creation of invalid route identifier', () async {
      await expectLater(
        () async => dartFrogNewMiddleware('/👯‍', directory: projectDirectory),
        failsWith(stderr: 'Route path segments must be valid Dart identifiers'),
      );
    });

    test('Excuse middleware creation of doubled route params', () async {
      await expectLater(
        () async => dartFrogNewMiddleware(
          '/[id]/something/[id]',
          directory: projectDirectory,
        ),
        failsWith(
          stderr:
              'Failed to create middleware: '
              'Duplicate parameter name found: id',
        ),
      );
    });

    group('Invalid states', () {
      // These tests create invalid states that may break other tests if
      // running in parallel on shared files.

      const projectName = 'error_project';

      late Directory testDirectory;
      late Directory routesDirectory;
      late Directory projectDirectory;

      setUp(() async {
        testDirectory = tempDirectory.createTempSync(projectName);
        await dartFrogCreate(
          projectName: projectName,
          directory: testDirectory,
        );

        projectDirectory = Directory(
          path.join(testDirectory.path, projectName),
        );

        routesDirectory = Directory(path.join(projectDirectory.path, 'routes'));
      });

      tearDown(() async {
        await projectDirectory.delete(recursive: true);
      });

      test('Excuse middleware creation upon existing rogue routes', () async {
        await dartFrogNewRoute('/existing_rogue', directory: projectDirectory);

        Directory(
          path.join(routesDirectory.path, 'existing_rogue'),
        ).createSync(recursive: true);

        await expectLater(
          () async => dartFrogNewMiddleware(
            '/existing_rogue',
            directory: projectDirectory,
          ),
          failsWith(
            stderr:
                'Failed to create middleware: Rogue route detected. '
                'Rename routes${slash}existing_rogue.dart to '
                'routes${slash}existing_rogue${slash}index.dart.',
          ),
        );
      });

      test(
        'Excuse middleware creation upon existing route conflicts',
        () async {
          await dartFrogNewRoute(
            '/conflicting_route',
            directory: projectDirectory,
          );

          File(
            path.join(routesDirectory.path, 'conflicting_route/index.dart'),
          ).createSync(recursive: true);

          await expectLater(
            () async => dartFrogNewMiddleware(
              '/conflicting_route',
              directory: projectDirectory,
            ),
            failsWith(
              stderr:
                  'Failed to create middleware: Route conflict detected. '
                  'routes${slash}conflicting_route.dart and '
                  'routes${slash}conflicting_route${slash}index.dart both '
                  'resolve to /conflicting_route.',
            ),
          );
        },
      );
    });
  });
}
