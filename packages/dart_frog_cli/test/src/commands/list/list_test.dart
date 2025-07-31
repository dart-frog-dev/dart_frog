// ignore_for_file: no_adjacent_strings_in_list
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_frog_cli/src/command_runner.dart';
import 'package:dart_frog_cli/src/commands/commands.dart';
import 'package:dart_frog_gen/dart_frog_gen.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

class _MockArgResults extends Mock implements ArgResults {}

class _MockLogger extends Mock implements Logger {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockProcessSignal extends Mock implements ProcessSignal {}

class _MockProgress extends Mock implements Progress {}

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

class _MockRouteConfiguration extends Mock implements RouteConfiguration {}

class _MockStdin extends Mock implements Stdin {}

const expectedUsage = [
  'Lists the routes on a Dart Frog project.\n'
      '\n'
      'Usage: dart_frog list "path/to/project"\n'
      '-h, --help     Print this usage information.\n'
      '-p, --plain    Return the output in a plain format, printing each route '
      'on a new line.\n'
      '\n'
      'Run "dart_frog help" to see global options.',
];

void main() {
  group('dart_frog list', () {
    setUpAll(() {
      registerFallbackValue(_FakeDirectoryGeneratorTarget());
    });

    late ArgResults argResults;
    late Logger logger;
    late Progress progress;
    late ListCommand command;
    late DartFrogCommandRunner commandRunner;
    late RouteConfiguration routeConfiguration;

    setUp(() {
      argResults = _MockArgResults();
      logger = _MockLogger();
      progress = _MockProgress();
      routeConfiguration = _MockRouteConfiguration();
      when(() => logger.progress(any())).thenReturn(progress);
      command =
          ListCommand(
              logger: logger,
              buildConfiguration: (_) => routeConfiguration,
            )
            ..testArgResults = argResults
            ..testUsage = 'test usage';

      when(() => argResults['plain']).thenReturn(false);

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
      'usage shows help text',
      overridePrint((printLogs) async {
        final result = await commandRunner.run(['list', '--help']);

        expect(result, equals(ExitCode.success.code));
        expect(printLogs, expectedUsage);
      }),
    );

    test('logs all the endpoints', () async {
      when(
        () => routeConfiguration.endpoints,
      ).thenReturn({'/turles/<id>': [], '/turles/random': []});
      final directory = Directory.systemTemp.createTempSync();

      command.testCwd = directory;

      when(() => argResults.rest).thenReturn(['my_project']);

      await expectLater(await command.run(), equals(ExitCode.success.code));

      verify(() => logger.info('Route list 🐸:')).called(1);
      verify(() => logger.info('==============\n')).called(1);
      verify(() => logger.info('/turles/<id>')).called(1);
      verify(() => logger.info('/turles/random')).called(1);
    });

    test('logs all the endpoints in plain mode', () async {
      when(() => argResults['plain']).thenReturn(true);

      when(
        () => routeConfiguration.endpoints,
      ).thenReturn({'/turles/<id>': [], '/turles/random': []});
      final directory = Directory.systemTemp.createTempSync();

      command.testCwd = directory;

      when(() => argResults.rest).thenReturn(['my_project']);

      await expectLater(await command.run(), equals(ExitCode.success.code));

      verifyNever(() => logger.info('Route list 🐸:'));
      verifyNever(() => logger.info('==============\n'));
      verify(() => logger.info('/turles/<id>')).called(1);
      verify(() => logger.info('/turles/random')).called(1);
    });

    test(
      'logs all the endpoints of the current dir when a project is ommited',
      () async {
        when(
          () => routeConfiguration.endpoints,
        ).thenReturn({'/turles/<id>': [], '/turles/random': []});
        final directory = Directory.systemTemp.createTempSync();

        command.testCwd = directory;

        when(() => argResults.rest).thenReturn([]);

        await expectLater(await command.run(), equals(ExitCode.success.code));

        verify(() => logger.info('Route list 🐸:')).called(1);
        verify(() => logger.info('==============\n')).called(1);
        verify(() => logger.info('/turles/<id>')).called(1);
        verify(() => logger.info('/turles/random')).called(1);
      },
    );

    test('fails when multiple directories are specified', () async {
      final directory = Directory.systemTemp.createTempSync();

      command.testCwd = directory;

      when(() => argResults.rest).thenReturn(['a', 'b']);

      await expectLater(
        () async => command.run(),
        throwsA(
          isA<UsageException>().having(
            (p) => p.message,
            'error message',
            'Multiple project directories specified.',
          ),
        ),
      );
    });
  });
}
