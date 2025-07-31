import 'dart:async';
import 'dart:io';

import 'package:dart_frog_cli/src/command_runner.dart';
import 'package:dart_frog_cli/src/commands/daemon/daemon.dart';
import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

class _MockDaemonServer extends Mock implements DaemonServer {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockLogger extends Mock implements Logger {}

class _MockProcessSignal extends Mock implements ProcessSignal {}

class _MockStdin extends Mock implements Stdin {}

const expectedUsage = [
  // ignore: no_adjacent_strings_in_list
  'Start the Dart Frog daemon\n'
      '\n'
      'Usage: dart_frog daemon [arguments]\n'
      '-h, --help    Print this usage information.\n'
      '\n'
      'Run "dart_frog help" to see global options.',
];

void main() {
  group('dart_frog daemon', () {
    late DartFrogCommandRunner commandRunner;
    late Logger logger;

    setUp(() {
      logger = _MockLogger();

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

    test('runs with default value', () async {
      final command = DaemonCommand();

      final runFuture = command.run();

      await command.daemon.kill(ExitCode.success);

      await expectLater(runFuture, completion(ExitCode.success.code));
    });

    test(
      'usage shows help text',
      overridePrint((printLogs) async {
        final result = await commandRunner.run(['daemon', '--help']);

        expect(result, equals(ExitCode.success.code));
        expect(printLogs, expectedUsage);
      }),
    );

    test(
      'starts a daemon, waits for it to be completed and returns exit code',
      () async {
        final daemonServer = _MockDaemonServer();
        final completer = Completer<ExitCode>();
        when(() => daemonServer.exitCode).thenAnswer((_) => completer.future);
        final command = DaemonCommand(daemonBuilder: () => daemonServer);
        final future = command.run();
        verify(() => daemonServer.exitCode).called(1);
        completer.complete(ExitCode.success);
        final result = await future;
        expect(result, ExitCode.success.code);
      },
    );
  });
}
