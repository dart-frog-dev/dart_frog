import 'dart:io';

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockHookContext extends Mock implements HookContext {}

class _MockLogger extends Mock implements Logger {}

void main() {
  group('disableWorkspaceResolution', () {
    late List<int> exitCalls;
    late HookContext context;
    late Logger logger;
    late Directory projectDirectory;

    setUp(() {
      exitCalls = [];
      context = _MockHookContext();
      logger = _MockLogger();
      projectDirectory = Directory.systemTemp.createTempSync('project');

      when(() => context.logger).thenReturn(logger);

      addTearDown(() => projectDirectory.delete().ignore());
    });

    group('when pubspec_overrides.yaml does not exist', () {
      test('adds resolution: null', () {
        disableWorkspaceResolution(
          context,
          projectDirectory: projectDirectory.path,
          exit: exitCalls.add,
        );
        final contents = projectDirectory.listSync();
        expect(contents, hasLength(1));
        final pubspecOverrides = contents.first as File;
        expect(
          pubspecOverrides.readAsStringSync(),
          equals('resolution: null'),
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
          projectDirectory: projectDirectory.path,
          exit: exitCalls.add,
        );
        final contents = projectDirectory.listSync();
        expect(contents, hasLength(1));
        final pubspecOverrides = contents.first as File;
        expect(
          pubspecOverrides.readAsStringSync(),
          equals(
            '''
resolution: null
$originalPubspecOverridesContent''',
          ),
        );
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
          projectDirectory: projectDirectory.path,
          exit: exitCalls.add,
        );
        final contents = projectDirectory.listSync();
        expect(contents, hasLength(1));
        expect(exitCalls, equals([1]));
        verify(
          () => logger.err(any(that: contains('Permission denied'))),
        ).called(1);
      });
    });
  });
}
