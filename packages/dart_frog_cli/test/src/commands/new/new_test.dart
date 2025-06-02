// ignore_for_file: no_adjacent_strings_in_list
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_frog_cli/src/command_runner.dart';
import 'package:dart_frog_cli/src/commands/commands.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

class _MockArgResults extends Mock implements ArgResults {}

class _MockLogger extends Mock implements Logger {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockProcessSignal extends Mock implements ProcessSignal {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockGeneratorHooks extends Mock implements GeneratorHooks {}

class _MockProgress extends Mock implements Progress {}

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

class _MockStdin extends Mock implements Stdin {}

const expectedUsage = [
  'Create a new route or middleware for dart_frog\n'
      '\n'
      'Usage: dart_frog new <route|middleware> "path/to/route"\n'
      '-h, --help    Print this usage information.\n'
      '\n'
      'Available subcommands:\n'
      '  middleware   Create a new middleware for dart_frog\n'
      '  route        Create a new route for dart_frog\n'
      '\n'
      'Run "dart_frog help" to see global options.',
];

void main() {
  group('dart_frog new', () {
    setUpAll(() {
      registerFallbackValue(_FakeDirectoryGeneratorTarget());
    });

    late ArgResults argResults;
    late Logger logger;
    late Progress progress;
    late MasonGenerator generator;
    late NewCommand command;
    late DartFrogCommandRunner commandRunner;

    setUp(() {
      argResults = _MockArgResults();
      logger = _MockLogger();
      progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      generator = _MockMasonGenerator();
      command =
          NewCommand(
              logger: logger,
              generator: (_) async {
                return generator;
              },
            )
            ..testArgResults = argResults
            ..testUsage = 'test usage';

      final sigint = _MockProcessSignal();

      when(sigint.watch).thenAnswer((_) => const Stream.empty());

      commandRunner = DartFrogCommandRunner(
        logger: logger,
        pubUpdater: _MockPubUpdater(),
        exit: (_) {},
        sigint: sigint,
        stdin: _MockStdin(),
      );
    });

    test(
      'usage shows sub commands',
      overridePrint((printLogs) async {
        final result = await commandRunner.run(['new', '--help']);

        expect(result, equals(ExitCode.success.code));
        expect(printLogs, expectedUsage);
      }),
    );

    test('fails when the route path is not specified', () async {
      final generatorHooks = _MockGeneratorHooks();
      final directory = Directory.systemTemp.createTempSync();

      when(
        () => generatorHooks.preGen(
          vars: any(named: 'vars'),
          workingDirectory: any(named: 'workingDirectory'),
          onVarsChanged: any(named: 'onVarsChanged'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => generatorHooks.postGen(
          vars: any(named: 'vars'),
          workingDirectory: any(named: 'workingDirectory'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) async {});

      when(() => generator.hooks).thenReturn(generatorHooks);

      when(
        () => generator.generate(any(), vars: any(named: 'vars')),
      ).thenAnswer((_) async => []);

      Directory('${directory.path}/routes').createSync(recursive: true);

      when(() => argResults.rest).thenReturn([]);

      command.newRouteCommand.testCwd = directory;

      await expectLater(
        () async => await command.newRouteCommand.run(),
        throwsA(
          isA<UsageException>().having(
            (p) => p.message,
            'error message',
            'Provide a route path for the new route',
          ),
        ),
      );
    });

    group('fails when the route path is invalid', () {
      test('fails when the route path has invalid character', () async {
        final generatorHooks = _MockGeneratorHooks();
        final directory = Directory.systemTemp.createTempSync();

        when(
          () => generatorHooks.preGen(
            vars: any(named: 'vars'),
            workingDirectory: any(named: 'workingDirectory'),
            onVarsChanged: any(named: 'onVarsChanged'),
            logger: any(named: 'logger'),
          ),
        ).thenAnswer((_) async {});

        when(
          () => generatorHooks.postGen(
            vars: any(named: 'vars'),
            workingDirectory: any(named: 'workingDirectory'),
            logger: any(named: 'logger'),
          ),
        ).thenAnswer((_) async {});

        when(() => generator.hooks).thenReturn(generatorHooks);

        when(
          () => generator.generate(any(), vars: any(named: 'vars')),
        ).thenAnswer((_) async => []);

        Directory('${directory.path}/routes').createSync(recursive: true);

        when(() => argResults.rest).thenReturn(['user/[id]/🦅']);

        command.newRouteCommand.testCwd = directory;

        await expectLater(
          () async => await command.newRouteCommand.run(),
          throwsA(
            isA<UsageException>().having(
              (p) => p.message,
              'error message',
              'Route path segments must be valid Dart identifiers',
            ),
          ),
        );
      });

      test('fails when there is empty segments', () async {
        final generatorHooks = _MockGeneratorHooks();
        final directory = Directory.systemTemp.createTempSync();

        when(
          () => generatorHooks.preGen(
            vars: any(named: 'vars'),
            workingDirectory: any(named: 'workingDirectory'),
            onVarsChanged: any(named: 'onVarsChanged'),
            logger: any(named: 'logger'),
          ),
        ).thenAnswer((_) async {});

        when(
          () => generatorHooks.postGen(
            vars: any(named: 'vars'),
            workingDirectory: any(named: 'workingDirectory'),
            logger: any(named: 'logger'),
          ),
        ).thenAnswer((_) async {});

        when(() => generator.hooks).thenReturn(generatorHooks);

        when(
          () => generator.generate(any(), vars: any(named: 'vars')),
        ).thenAnswer((_) async => []);

        Directory('${directory.path}/routes').createSync(recursive: true);

        when(() => argResults.rest).thenReturn(['/user/[id]//route']);

        command.newRouteCommand.testCwd = directory;

        await expectLater(
          () async => await command.newRouteCommand.run(),
          throwsA(
            isA<UsageException>().having(
              (p) => p.message,
              'error message',
              'Route path cannot contain empty segments',
            ),
          ),
        );
      });
    });

    test('fails when the route path is empty', () async {
      final generatorHooks = _MockGeneratorHooks();
      final directory = Directory.systemTemp.createTempSync();

      when(
        () => generatorHooks.preGen(
          vars: any(named: 'vars'),
          workingDirectory: any(named: 'workingDirectory'),
          onVarsChanged: any(named: 'onVarsChanged'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => generatorHooks.postGen(
          vars: any(named: 'vars'),
          workingDirectory: any(named: 'workingDirectory'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) async {});

      when(() => generator.hooks).thenReturn(generatorHooks);

      when(
        () => generator.generate(any(), vars: any(named: 'vars')),
      ).thenAnswer((_) async => []);

      Directory('${directory.path}/routes').createSync(recursive: true);

      when(() => argResults.rest).thenReturn(['']);

      command.newRouteCommand.testCwd = directory;

      await expectLater(
        () async => await command.newRouteCommand.run(),
        throwsA(
          isA<UsageException>().having(
            (p) => p.message,
            'error message',
            'Route path must not be empty',
          ),
        ),
      );
    });

    test('fails when there is no routes directory', () async {
      final generatorHooks = _MockGeneratorHooks();
      final directory = Directory.systemTemp.createTempSync();

      when(
        () => generatorHooks.preGen(
          vars: any(named: 'vars'),
          workingDirectory: any(named: 'workingDirectory'),
          onVarsChanged: any(named: 'onVarsChanged'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => generatorHooks.postGen(
          vars: any(named: 'vars'),
          workingDirectory: any(named: 'workingDirectory'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) async {});

      when(() => generator.hooks).thenReturn(generatorHooks);

      when(
        () => generator.generate(any(), vars: any(named: 'vars')),
      ).thenAnswer((_) async => []);

      when(
        () => argResults.rest,
      ).thenReturn(['user/[id]/posts/[post_id]/comments']);

      command.newRouteCommand.testCwd = directory;

      await expectLater(
        () async => await command.newRouteCommand.run(),
        throwsA(
          isA<UsageException>().having(
            (p) => p.message,
            'error message',
            'No "routes" directory found in the current directory. '
                'Make sure to run this command on a dart_frog project.',
          ),
        ),
      );
    });

    test('fails with "software" when pre-gen fails', () async {
      final generatorHooks = _MockGeneratorHooks();
      final directory = Directory.systemTemp.createTempSync();

      when(
        () => generatorHooks.preGen(
          vars: any(named: 'vars'),
          workingDirectory: any(named: 'workingDirectory'),
          onVarsChanged: any(named: 'onVarsChanged'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => generatorHooks.postGen(
          vars: any(named: 'vars'),
          workingDirectory: any(named: 'workingDirectory'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) async {});

      when(() => generator.hooks).thenReturn(generatorHooks);

      when(
        () => generator.generate(any(), vars: any(named: 'vars')),
      ).thenAnswer((_) async => []);

      Directory('${directory.path}/routes').createSync(recursive: true);

      when(
        () => argResults.rest,
      ).thenReturn(['user/[id]/posts/[post_id]/comments']);

      command.newRouteCommand.testCwd = directory;

      final exitCode = await command.newRouteCommand.run();

      expect(exitCode, equals(ExitCode.software.code));
    });

    group('dart_frog new route', () {
      test('creates a route successfully', () async {
        final generatorHooks = _MockGeneratorHooks();
        final directory = Directory.systemTemp.createTempSync();

        when(
          () => generatorHooks.preGen(
            vars: any(named: 'vars'),
            workingDirectory: any(named: 'workingDirectory'),
            onVarsChanged: any(named: 'onVarsChanged'),
            logger: any(named: 'logger'),
          ),
        ).thenAnswer((invocation) async {
          final onVarsChanged =
              invocation.namedArguments[#onVarsChanged]
                  as void Function(Map<String, dynamic>);

          onVarsChanged({'dir_path': '${directory.path}/routes/something'});
        });

        when(
          () => generatorHooks.postGen(
            vars: any(named: 'vars'),
            workingDirectory: any(named: 'workingDirectory'),
            logger: any(named: 'logger'),
          ),
        ).thenAnswer((_) async {});

        when(() => generator.hooks).thenReturn(generatorHooks);

        when(
          () => generator.generate(any(), vars: any(named: 'vars')),
        ).thenAnswer((_) async => []);

        Directory('${directory.path}/routes').createSync(recursive: true);

        when(
          () => argResults.rest,
        ).thenReturn(['/user/[id]/posts/[post_id]/comments']);

        command.newRouteCommand.testCwd = directory;

        final exitCode = await command.newRouteCommand.run();

        expect(exitCode, equals(ExitCode.success.code));

        verify(() {
          generatorHooks.preGen(
            vars: {
              'route_path': '/user/[id]/posts/[post_id]/comments',
              'type': 'route',
              'dir_path': '${directory.path}/routes/something',
            },
            workingDirectory: any(named: 'workingDirectory'),
            onVarsChanged: any(named: 'onVarsChanged'),
            logger: any(named: 'logger'),
          );
        });

        verify(() {
          generatorHooks.postGen(
            vars: {
              'route_path': '/user/[id]/posts/[post_id]/comments',
              'type': 'route',
              'dir_path': '${directory.path}/routes/something',
            },
            workingDirectory: any(named: 'workingDirectory'),
            logger: any(named: 'logger'),
          );
        });
      });
    });

    group('dart_frog new middleware', () {
      test('creates a middleware successfully', () async {
        final generatorHooks = _MockGeneratorHooks();
        final directory = Directory.systemTemp.createTempSync();

        when(
          () => generatorHooks.preGen(
            vars: any(named: 'vars'),
            workingDirectory: any(named: 'workingDirectory'),
            onVarsChanged: any(named: 'onVarsChanged'),
            logger: any(named: 'logger'),
          ),
        ).thenAnswer((invocation) async {
          final onVarsChanged =
              invocation.namedArguments[#onVarsChanged]
                  as void Function(Map<String, dynamic>);

          onVarsChanged({'dir_path': '${directory.path}/routes/something'});
        });

        when(
          () => generatorHooks.postGen(
            vars: any(named: 'vars'),
            workingDirectory: any(named: 'workingDirectory'),
            logger: any(named: 'logger'),
          ),
        ).thenAnswer((_) async {});

        when(() => generator.hooks).thenReturn(generatorHooks);

        when(
          () => generator.generate(any(), vars: any(named: 'vars')),
        ).thenAnswer((_) async => []);

        Directory('${directory.path}/routes').createSync(recursive: true);

        when(
          () => argResults.rest,
        ).thenReturn(['user/[id]/posts/[post_id]/comments']);

        command.newMiddlewareCommand.testCwd = directory;

        final exitCode = await command.newMiddlewareCommand.run();

        expect(exitCode, equals(ExitCode.success.code));

        verify(() {
          generatorHooks.preGen(
            vars: {
              'route_path': 'user/[id]/posts/[post_id]/comments',
              'type': 'middleware',
              'dir_path': '${directory.path}/routes/something',
            },
            workingDirectory: any(named: 'workingDirectory'),
            onVarsChanged: any(named: 'onVarsChanged'),
            logger: any(named: 'logger'),
          );
        });

        verify(() {
          generatorHooks.postGen(
            vars: {
              'route_path': 'user/[id]/posts/[post_id]/comments',
              'type': 'middleware',
              'dir_path': '${directory.path}/routes/something',
            },
            workingDirectory: any(named: 'workingDirectory'),
            logger: any(named: 'logger'),
          );
        });
      });
    });
  });
}
