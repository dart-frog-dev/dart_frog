import 'dart:io' as io;

import 'package:dart_frog_gen/dart_frog_gen.dart';
import 'package:dart_frog_new_hooks/pre_gen.dart';
import 'package:dart_frog_new_hooks/src/exit_overrides.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockRouteConfiguration extends Mock implements RouteConfiguration {}

class _FakeHookContext extends Fake implements HookContext {
  _FakeHookContext({Logger? logger}) : _logger = logger ?? _MockLogger();

  final Logger _logger;

  var _vars = <String, dynamic>{};

  @override
  Map<String, dynamic> get vars => _vars;

  @override
  set vars(Map<String, dynamic> value) => _vars = value;

  @override
  Logger get logger => _logger;
}

const validRouteConfiguration = RouteConfiguration(
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

void main() {
  group('preGen', () {
    late HookContext context;
    late Logger logger;

    setUp(() {
      logger = _MockLogger();
      context = _FakeHookContext(logger: logger);
    });

    test('preGen completes', () {
      expect(
        ExitOverrides.runZoned(
          () async => preGen(
            _FakeHookContext(),
            buildConfiguration: (_) {
              throw Exception('oops');
            },
          ),
          exit: (_) {},
        ),
        completes,
      );
    });

    test('exit(1) if buildRouteConfiguration throws', () {
      final exitCalls = <int>[];
      final exception = Exception('oops');
      preGen(
        context,
        buildConfiguration: (_) => throw exception,
        exit: exitCalls.add,
      );
      expect(exitCalls, equals([1]));
      verify(() => logger.err(exception.toString())).called(1);
    });

    test('exit(1) for invalid route config', () {
      final configuration = _MockRouteConfiguration();
      when(() => configuration.rogueRoutes).thenReturn(
        const [
          RouteFile(
            name: 'hello',
            path: 'hello.dart',
            route: '/hello',
            params: [],
            wildcard: false,
          ),
        ],
      );

      context.vars['type'] = 'route';

      final exitCalls = <int>[];
      preGen(
        context,
        buildConfiguration: (_) => configuration,
        exit: exitCalls.add,
      );

      verify(
        () => logger.err(
          '''Failed to create route: Rogue route detected.${defaultForeground.wrap(' ')}Rename ${lightCyan.wrap('routes/hello.dart')} to ${lightCyan.wrap('routes/hello/index.dart')}.''',
        ),
      );
      expect(exitCalls, equals([1]));
    });

    test('exit(1) for invalid type', () {
      final exitCalls = <int>[];

      context.vars['type'] = 'invalid';
      context.vars['route_path'] = '/[id]/existing_as_dir';
      preGen(
        context,
        buildConfiguration: (_) => validRouteConfiguration,
        exit: exitCalls.add,
      );
      verify(
        () => logger.err(
          '''Unrecognized type: invalid''',
        ),
      );
      expect(exitCalls, equals([1]));
    });

    group('Type: route', () {
      late io.Directory directory;
      late List<int> exitCalls;
      setUp(() {
        directory = io.Directory.systemTemp.createTempSync(
          'dart_frog_new_hooks_test',
        );
        exitCalls = <int>[];
        context.vars['type'] = 'route';
      });
      tearDown(() {
        directory.deleteSync(recursive: true);
      });

      test('exit(1) if route already exists as dir endpoint', () {
        context.vars['route_path'] = '/[id]/existing_as_dir';
        preGen(
          context,
          buildConfiguration: (_) => validRouteConfiguration,
          exit: exitCalls.add,
          directory: directory,
        );
        verify(
          () => logger.err(
            '''Failed to create route: /<id>/existing_as_dir already exists.''',
          ),
        );
        expect(exitCalls, equals([1]));
      });

      test('exit(1) if route already exists as file endpoint', () {
        context.vars['route_path'] = '/[id]/existing_as_file';

        preGen(
          context,
          buildConfiguration: (_) => validRouteConfiguration,
          exit: exitCalls.add,
          directory: directory,
        );

        verify(
          () => logger.err(
            '''Failed to create route: /<id>/existing_as_file already exists.''',
          ),
        );
        expect(exitCalls, equals([1]));
      });

      test('exit(1) if route has duplicate parameter names', () {
        final exitCalls = <int>[];
        context.vars['route_path'] = '/[id]/[id]';

        preGen(
          context,
          buildConfiguration: (_) => validRouteConfiguration,
          exit: exitCalls.add,
          directory: directory,
        );

        verify(
          () => logger.err(
            '''Failed to create route: Duplicate parameter name found: id''',
          ),
        );
        expect(exitCalls, equals([1]));
      });

      test('Renames a wrapping route that exists as file to an index', () {
        final filePath = path.join(
          directory.path,
          'routes',
          '[id]',
          'existing_as_file.dart',
        );
        io.File(filePath)
          ..createSync(recursive: true)
          ..writeAsStringSync('content');

        context.vars['route_path'] = '/[id]/existing_as_file/new_route';

        preGen(
          context,
          buildConfiguration: (_) => validRouteConfiguration,
          exit: exitCalls.add,
          directory: directory,
        );

        expect(io.File(filePath).existsSync(), isFalse);

        final newFilepath = path.join(
          directory.path,
          'routes',
          '[id]',
          'existing_as_file',
          'index.dart',
        );

        expect(io.File(newFilepath).readAsStringSync(), equals('content'));

        expect(
          context.vars['dir_path'],
          path.relative(
            path.join(directory.path, 'routes', '[id]', 'existing_as_file'),
          ),
        );
        expect(context.vars['filename'], 'new_route.dart');
        expect(context.vars['params'], ['id']);
        expect(context.vars['is_route'], true);

        expect(exitCalls, isEmpty);
      });

      test(
        'New route is index if its path is already represented by a directory',
        () {
          final subDirPath = path.join(directory.path, 'routes', '[id]');

          io.Directory(subDirPath).createSync(recursive: true);

          context.vars['route_path'] = '/[id]';

          preGen(
            context,
            buildConfiguration: (_) => validRouteConfiguration,
            exit: exitCalls.add,
            directory: directory,
          );

          expect(
            context.vars['dir_path'],
            path.relative(path.join(directory.path, 'routes', '[id]')),
          );
          expect(context.vars['filename'], 'index.dart');
          expect(context.vars['params'], ['id']);
          expect(context.vars['is_route'], true);

          expect(exitCalls, isEmpty);
        },
      );

      test('New route is a not index if not represented by a directory', () {
        context.vars['route_path'] = '/[id]/this/is/[a]/new_route';

        preGen(
          context,
          buildConfiguration: (_) => validRouteConfiguration,
          exit: exitCalls.add,
          directory: directory,
        );

        expect(
          context.vars['dir_path'],
          path.relative(
            path.join(directory.path, 'routes', '[id]', 'this', 'is', '[a]'),
          ),
        );

        expect(context.vars['filename'], 'new_route.dart');
        expect(context.vars['params'], ['id', 'a']);
        expect(context.vars['is_route'], true);

        expect(exitCalls, isEmpty);
      });
    });

    group('Type: middleware', () {
      setUp(() {
        context.vars['type'] = 'middleware';
      });

      test('exit(1) if middleware already exists (global)', () {
        final exitCalls = <int>[];

        final directory = io.Directory.systemTemp.createTempSync(
          'dart_frog_new_hooks_test',
        );
        addTearDown(() {
          directory.deleteSync(recursive: true);
        });
        final filePath = path.join(
          directory.path,
          'routes',
          '_middleware.dart',
        );
        io.File(filePath)
          ..createSync(recursive: true)
          ..writeAsStringSync('content');

        context.vars['route_path'] = '/';
        preGen(
          context,
          buildConfiguration: (_) => validRouteConfiguration,
          exit: exitCalls.add,
          directory: directory,
        );

        verify(
          () => logger.err(
            '''There is already a middleware at ${path.relative(filePath)}''',
          ),
        );
        expect(exitCalls, equals([1]));
      });

      test('exit(1) if middleware already exists (local)', () {
        final exitCalls = <int>[];

        final directory = io.Directory.systemTemp.createTempSync(
          'dart_frog_new_hooks_test',
        );
        addTearDown(() {
          directory.deleteSync(recursive: true);
        });
        final filePath =
            path.join(directory.path, 'routes', '[id]', '_middleware.dart');
        io.File(filePath)
          ..createSync(recursive: true)
          ..writeAsStringSync('content');

        context.vars['route_path'] = '/[id]';
        preGen(
          context,
          buildConfiguration: (_) => validRouteConfiguration,
          exit: exitCalls.add,
          directory: directory,
        );

        verify(
          () => logger.err(
            '''There is already a middleware at ${path.relative(filePath)}''',
          ),
        );
        expect(exitCalls, equals([1]));
      });

      test('exit(1) if route path has duplicate parameter names', () {
        final exitCalls = <int>[];
        context.vars['route_path'] = '/[id]/[id]';

        final directory = io.Directory.systemTemp.createTempSync(
          'dart_frog_new_hooks_test',
        );
        addTearDown(() {
          directory.deleteSync(recursive: true);
        });

        preGen(
          context,
          buildConfiguration: (_) => validRouteConfiguration,
          exit: exitCalls.add,
          directory: directory,
        );

        verify(
          () => logger.err(
            '''Failed to create middleware: Duplicate parameter name found: id''',
          ),
        );
        expect(exitCalls, equals([1]));
      });

      test('exit(1) if creating middleware inside middleware', () {
        final exitCalls = <int>[];
        context.vars['route_path'] = '/_middleware';

        final directory = io.Directory.systemTemp.createTempSync(
          'dart_frog_new_hooks_test',
        );
        addTearDown(() {
          directory.deleteSync(recursive: true);
        });

        preGen(
          context,
          buildConfiguration: (_) => validRouteConfiguration,
          exit: exitCalls.add,
          directory: directory,
        );

        verify(
          () => logger.err(
            '''Cannot create middleware inside another middleware.''',
          ),
        );
        expect(exitCalls, equals([1]));
      });

      test('Renames a wrapping route that exists as file to an index', () {
        final exitCalls = <int>[];

        final directory = io.Directory.systemTemp.createTempSync(
          'dart_frog_new_hooks_test',
        );
        addTearDown(() {
          directory.deleteSync(recursive: true);
        });
        final filePath = path.join(
          directory.path,
          'routes',
          '[id]',
          'existing_as_file.dart',
        );
        io.File(filePath)
          ..createSync(recursive: true)
          ..writeAsStringSync('content');

        context.vars['route_path'] = '/[id]/existing_as_file';

        preGen(
          context,
          buildConfiguration: (_) => validRouteConfiguration,
          exit: exitCalls.add,
          directory: directory,
        );

        expect(io.File(filePath).existsSync(), isFalse);

        final newFilepath = path.join(
          directory.path,
          'routes',
          '[id]',
          'existing_as_file',
          'index.dart',
        );

        expect(io.File(newFilepath).readAsStringSync(), equals('content'));
        expect(
          context.vars['dir_path'],
          path.relative(
            path.join(directory.path, 'routes', '[id]', 'existing_as_file'),
          ),
        );
        expect(context.vars['filename'], '_middleware.dart');
        expect(context.vars['is_middleware'], true);

        expect(exitCalls, isEmpty);
      });

      test('Sets up a middleware path correctly', () {
        final exitCalls = <int>[];

        final directory = io.Directory.systemTemp.createTempSync(
          'dart_frog_new_hooks_test',
        );
        addTearDown(() {
          directory.deleteSync(recursive: true);
        });

        context.vars['route_path'] = '/[id]/existing_as_dir';
        preGen(
          context,
          buildConfiguration: (_) => validRouteConfiguration,
          exit: exitCalls.add,
          directory: directory,
        );

        expect(
          context.vars['dir_path'],
          path.relative(
            path.join(directory.path, 'routes', '[id]', 'existing_as_dir'),
          ),
        );
        expect(context.vars['filename'], '_middleware.dart');
        expect(context.vars['is_middleware'], true);

        expect(exitCalls, isEmpty);
      });
    });
  });
}
