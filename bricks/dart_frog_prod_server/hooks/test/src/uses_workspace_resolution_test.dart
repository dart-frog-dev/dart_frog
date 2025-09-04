import 'dart:io';

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockHookContext extends Mock implements HookContext {}

class _MockLogger extends Mock implements Logger {}

void main() {
  group('usesWorkspaceResolution', () {
    late List<int> exitCalls;
    late HookContext context;
    late Logger logger;
    late Directory buildDirectory;
    late Directory workingDirectory;

    setUp(() {
      exitCalls = [];
      context = _MockHookContext();
      logger = _MockLogger();
      buildDirectory = Directory.systemTemp.createTempSync('build');
      workingDirectory = Directory.systemTemp.createTempSync('working');

      when(() => context.logger).thenReturn(logger);

      addTearDown(() {
        buildDirectory.delete().ignore();
        workingDirectory.delete().ignore();
      });
    });

    group('when pubspec.yaml does not exist', () {
      test('returns false', () {
        expect(
          usesWorkspaceResolution(
            context,
            workingDirectory: workingDirectory.path,
            exit: exitCalls.add,
          ),
          isFalse,
        );
      });
    });

    group('when pubspec.yaml is malformed', () {
      late File pubspecFile;
      setUp(() {
        pubspecFile = File(
          path.join(workingDirectory.path, 'pubspec.yaml'),
        )..writeAsStringSync('invalid pubspec.yaml');
      });

      test('returns false', () {
        expect(
          usesWorkspaceResolution(
            context,
            workingDirectory: workingDirectory.path,
            exit: exitCalls.add,
          ),
          isFalse,
        );
        expect(exitCalls, equals([1]));
        verify(
          () => logger.err(
            any(that: contains('Unable to parse ${pubspecFile.path}')),
          ),
        );
      });
    });

    group('when pubspec.yaml is valid with no resolution', () {
      setUp(() {
        File(
          path.join(workingDirectory.path, 'pubspec.yaml'),
        ).writeAsStringSync('''
name: _
''');
      });

      test('returns false', () {
        expect(
          usesWorkspaceResolution(
            context,
            workingDirectory: workingDirectory.path,
            exit: exitCalls.add,
          ),
          isFalse,
        );
        expect(exitCalls, isEmpty);
        verifyNever(() => logger.err(any()));
      });
    });

    group('when pubspec.yaml is valid with resolution workspace', () {
      setUp(() {
        File(
          path.join(workingDirectory.path, 'pubspec.yaml'),
        ).writeAsStringSync('''
name: _
resolution: workspace
''');
      });

      test('returns true', () {
        expect(
          usesWorkspaceResolution(
            context,
            workingDirectory: workingDirectory.path,
            exit: exitCalls.add,
          ),
          isTrue,
        );
        expect(exitCalls, isEmpty);
        verifyNever(() => logger.err(any()));
      });
    });
  });
}
