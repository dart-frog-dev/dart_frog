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
    late Directory buildDirectory;

    setUp(() {
      exitCalls = [];
      context = _MockHookContext();
      logger = _MockLogger();
      buildDirectory = Directory.systemTemp.createTempSync('build');

      when(() => context.logger).thenReturn(logger);

      addTearDown(() => buildDirectory.delete().ignore());
    });

    group('when pubspec_overrides.yaml does not exist', () {
      test('adds resolution: null', () {
        disableWorkspaceResolution(
          context,
          buildDirectory: buildDirectory.path,
          exit: exitCalls.add,
        );
        final buildDirectoryContents = buildDirectory.listSync();
        expect(buildDirectoryContents, hasLength(1));
        final pubspecOverrides = buildDirectoryContents.first as File;
        expect(pubspecOverrides.readAsStringSync(), equals('''

resolution: null
'''));
      });
    });

    group('when pubspec_overrides.yaml exists', () {
      const originalPubspecOverridesContent = '''
dependency_overrides:
  foo:
    path: ./path/to/foo''';

      setUp(() {
        File(path.join(buildDirectory.path, 'pubspec_overrides.yaml'))
            .writeAsStringSync(originalPubspecOverridesContent);
      });

      test('adds resolution: null', () {
        disableWorkspaceResolution(
          context,
          buildDirectory: buildDirectory.path,
          exit: exitCalls.add,
        );
        final buildDirectoryContents = buildDirectory.listSync();
        expect(buildDirectoryContents, hasLength(1));
        final pubspecOverrides = buildDirectoryContents.first as File;
        expect(pubspecOverrides.readAsStringSync(), equals('''
$originalPubspecOverridesContent
resolution: null
'''));
      });
    });

    group('when unable to read pubspec_overrides', () {
      setUp(() {
        final pubspecOverrides = File(
          path.join(buildDirectory.path, 'pubspec_overrides.yaml'),
        )..createSync();
        Process.runSync('chmod', ['000', pubspecOverrides.path]);
      });

      test('exits with error', () {
        disableWorkspaceResolution(
          context,
          buildDirectory: buildDirectory.path,
          exit: exitCalls.add,
        );
        final buildDirectoryContents = buildDirectory.listSync();
        expect(buildDirectoryContents, hasLength(1));
        expect(exitCalls, equals([1]));
        verify(
          () => logger.err(any(that: contains('Permission denied'))),
        ).called(1);
      });
    });
  });
}
