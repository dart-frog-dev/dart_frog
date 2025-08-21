import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_frog_cli/src/commands/commands.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockArgResults extends Mock implements ArgResults {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockGeneratorHooks extends Mock implements GeneratorHooks {}

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

void main() {
  group('dart_frog create', () {
    setUpAll(() {
      registerFallbackValue(_FakeDirectoryGeneratorTarget());
    });

    late ArgResults argResults;
    late Logger logger;
    late Progress progress;
    late MasonGenerator generator;
    late CreateCommand command;

    setUp(() {
      argResults = _MockArgResults();
      logger = _MockLogger();
      progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      generator = _MockMasonGenerator();
      command = CreateCommand(
        logger: logger,
        generator: (_) async => generator,
      )
        ..testArgResults = argResults
        ..testUsage = 'test usage';
    });

    test('throws UsageException when args is empty.', () async {
      when(() => argResults.rest).thenReturn([]);
      when<dynamic>(() => argResults['project-name']).thenReturn(null);
      expect(command.run, throwsA(isA<UsageException>()));
    });

    test('throws UsageException when too many args provided.', () async {
      when(() => argResults.rest).thenReturn(['too', 'many', 'args']);
      when<dynamic>(() => argResults['project-name']).thenReturn(null);
      expect(command.run, throwsA(isA<UsageException>()));
    });

    test('throws UsageException when project name is invalid.', () async {
      final directory = Directory.systemTemp.createTempSync();
      when(() => argResults.rest).thenReturn([directory.path]);
      when<dynamic>(
        () => argResults['project-name'],
      ).thenReturn('invalid name');
      expect(command.run, throwsA(isA<UsageException>()));
    });

    test('throws UsageException when project directory is invalid.', () async {
      final directory = Directory.systemTemp.createTempSync();
      when(() => argResults.rest).thenReturn([directory.path, directory.path]);
      when<dynamic>(() => argResults['project-name']).thenReturn(null);
      expect(command.run, throwsA(isA<UsageException>()));
    });

    test('generates a project successfully (defaults)', () async {
      final generatorHooks = _MockGeneratorHooks();
      final directory = Directory.current.absolute.path;
      when(
        () => generatorHooks.postGen(
          vars: any(named: 'vars'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async {});
      when(() => argResults.rest).thenReturn([directory]);
      when(
        () => generator.generate(any(), vars: any(named: 'vars')),
      ).thenAnswer((_) async => []);
      when(() => generator.hooks).thenReturn(generatorHooks);
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.success.code));
      verify(
        () => generator.generate(
          any(),
          vars: {'name': 'dart_frog_cli', 'output_directory': directory},
        ),
      ).called(1);
    });

    test('generates a project successfully (custom)', () async {
      final generatorHooks = _MockGeneratorHooks();
      final directory = Directory.current.absolute.path;
      const projectName = 'example';
      when(
        () => generatorHooks.postGen(
          vars: any(named: 'vars'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async {});
      when<dynamic>(() => argResults['project-name']).thenReturn(projectName);
      when(() => argResults.rest).thenReturn([directory]);
      when(
        () => generator.generate(any(), vars: any(named: 'vars')),
      ).thenAnswer((_) async => []);
      when(() => generator.hooks).thenReturn(generatorHooks);
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.success.code));
      verify(
        () => generator.generate(
          any(),
          vars: {'name': projectName, 'output_directory': directory},
        ),
      ).called(1);
    });
  });
}
