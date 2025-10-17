import 'dart:io';

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_config/package_config.dart' hide Package;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockHookContext extends Mock implements HookContext {}

class _MockLogger extends Mock implements Logger {}

class _MockPackageConfig extends Mock implements PackageConfig {}

class _MockPackageGraph extends Mock implements PackageGraph {}

void main() {
  group('disableWorkspaceResolution', () {
    const packageName = 'server';

    late List<int> exitCalls;
    late HookContext context;
    late Logger logger;
    late Directory rootDirectory;
    late Directory projectDirectory;
    late PackageConfig packageConfig;
    late PackageGraph packageGraph;

    setUp(() {
      exitCalls = [];
      context = _MockHookContext();
      logger = _MockLogger();
      rootDirectory = Directory.systemTemp.createTempSync('root');
      projectDirectory = Directory(
        path.join(rootDirectory.path, 'packages', 'project'),
      )..createSync(recursive: true);
      File(path.join(projectDirectory.path, 'pubspec.yaml'))
          .writeAsStringSync('name: "$packageName"');
      packageConfig = _MockPackageConfig();
      packageGraph = _MockPackageGraph();

      when(() => context.logger).thenReturn(logger);
      when(() => packageGraph.roots).thenReturn([packageName, 'dart_frog']);
      when(() => packageGraph.packages).thenReturn(
        [
          const PackageGraphPackage(
            name: packageName,
            dependencies: ['dart_frog'],
            devDependencies: [],
            version: '1.0.0',
          ),
          const PackageGraphPackage(
            name: 'dart_frog',
            dependencies: [],
            devDependencies: [],
            version: '1.0.0',
          ),
        ],
      );
      when(() => packageConfig.packages).thenReturn([]);

      addTearDown(() => projectDirectory.delete().ignore());
    });

    group('when pubspec_overrides.yaml does not exist', () {
      test('adds resolution: null', () {
        disableWorkspaceResolution(
          context,
          packageConfig: packageConfig,
          packageGraph: packageGraph,
          projectDirectory: projectDirectory.path,
          workspaceRoot: rootDirectory.path,
          exit: exitCalls.add,
        );
        final contents = projectDirectory.listSync();
        expect(contents, hasLength(2));
        final pubspecOverrides = contents.firstWhere(
          (p) => path.basename(p.path) == 'pubspec_overrides.yaml',
        ) as File;
        expect(
          pubspecOverrides.readAsStringSync(),
          equals('''
resolution: null
dependency_overrides: {}
'''),
        );
      });
    });

    group('when pubspec_overrides.yaml exists', () {
      const originalPubspecOverridesContent = '''
dependency_overrides:
  foo:
    path: ./path/to/foo''';

      setUp(() {
        File(
          path.join(projectDirectory.path, 'pubspec_overrides.yaml'),
        ).writeAsStringSync(originalPubspecOverridesContent);
      });

      test('adds resolution: null', () {
        disableWorkspaceResolution(
          context,
          packageConfig: packageConfig,
          packageGraph: packageGraph,
          projectDirectory: projectDirectory.path,
          workspaceRoot: rootDirectory.path,
          exit: exitCalls.add,
        );
        final contents = projectDirectory.listSync();
        expect(contents, hasLength(2));
        final pubspecOverrides = contents.firstWhere(
          (p) => path.basename(p.path) == 'pubspec_overrides.yaml',
        ) as File;
        expect(
          pubspecOverrides.readAsStringSync(),
          equals(
            '''
$originalPubspecOverridesContent
resolution: null
''',
          ),
        );
      });

      group('when workspace root contains pubspec_overrides.yaml', () {
        const workspaceRootDartFrogOverride = '''
  dart_frog:
    git:
      url: https://github.com/dart-frog-dev/dart_frog
      path: packages/dart_frog''';
        const workspaceRootPubspecOverrides = '''
dependency_overrides:
$workspaceRootDartFrogOverride
    ''';

        setUp(() {
          File(
            path.join(rootDirectory.path, 'pubspec_overrides.yaml'),
          ).writeAsStringSync(workspaceRootPubspecOverrides);
        });

        test('adds root overrides', () {
          disableWorkspaceResolution(
            context,
            packageConfig: packageConfig,
            packageGraph: packageGraph,
            projectDirectory: projectDirectory.path,
            workspaceRoot: rootDirectory.path,
            exit: exitCalls.add,
          );
          final contents = projectDirectory.listSync();
          expect(contents, hasLength(2));
          final pubspecOverrides = contents.firstWhere(
            (p) => path.basename(p.path) == 'pubspec_overrides.yaml',
          ) as File;
          expect(
            pubspecOverrides.readAsStringSync(),
            equals(
              '''
$originalPubspecOverridesContent
$workspaceRootDartFrogOverride
resolution: null
''',
            ),
          );
        });
      });
    });

    group('when unable to read pubspec_overrides', () {
      setUp(() {
        final pubspecOverrides = File(
          path.join(projectDirectory.path, 'pubspec_overrides.yaml'),
        )..createSync();
        Process.runSync('chmod', ['000', pubspecOverrides.path]);
      });

      test('exits with error', () {
        disableWorkspaceResolution(
          context,
          packageConfig: packageConfig,
          packageGraph: packageGraph,
          projectDirectory: projectDirectory.path,
          workspaceRoot: rootDirectory.path,
          exit: exitCalls.add,
        );
        final contents = projectDirectory.listSync();
        expect(contents, hasLength(2));
        expect(exitCalls, equals([1]));
        verify(
          () => logger.err(any(that: contains('Permission denied'))),
        ).called(1);
      });
    });
  });
}
