import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_frog_cli/src/commands/commands.dart';
import 'package:dart_frog_cli/src/dev_server_runner/dev_server_runner.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockArgResults extends Mock implements ArgResults {}

class _MockLogger extends Mock implements Logger {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockDevServerRunner extends Mock implements DevServerRunner {}

class _MockStdin extends Mock implements Stdin {}

void main() {
  group('dart_frog dev', () {
    late ArgResults argResults;
    late MasonGenerator generator;
    late DevServerRunner runner;
    late Logger logger;
    late Stdin stdin;

    setUp(() {
      argResults = _MockArgResults();
      generator = _MockMasonGenerator();
      runner = _MockDevServerRunner();
      logger = _MockLogger();
      stdin = _MockStdin();

      when<dynamic>(() => argResults['port']).thenReturn('8080');
      when<dynamic>(
        () => argResults['dart-vm-service-port'],
      ).thenReturn('8181');
      when(() => argResults.rest).thenReturn(['--enable-experiment=macros']);
      when(() => stdin.hasTerminal).thenReturn(false);
    });

    test('can be instantiated', () {
      final command = DevCommand();
      expect(command, isNotNull);
    });

    test('run the dev server with the given parameters', () async {
      when(() => runner.start(any())).thenAnswer((_) => Future.value());
      when(
        () => runner.exitCode,
      ).thenAnswer((_) => Future.value(ExitCode.success));

      when(() => argResults['hostname']).thenReturn('192.168.1.2');
      when(() => argResults['port']).thenReturn('1234');
      when(() => argResults['dart-vm-service-port']).thenReturn('5678');
      when(() => argResults.rest).thenReturn(['--enable-experiment=macros']);

      final cwd = Directory.systemTemp;

      late String givenPort;
      late String givenDartVmServicePort;
      late InternetAddress? givenAddress;
      late MasonGenerator givenDevServerBundleGenerator;
      late Directory givenWorkingDirectory;
      late void Function()? givenOnHotReloadEnabled;

      final command =
          DevCommand(
              generator: (_) async => generator,
              devServerRunnerConstructor:
                  ({
                    required logger,
                    required port,
                    required address,
                    required devServerBundleGenerator,
                    required dartVmServicePort,
                    required workingDirectory,
                    void Function()? onHotReloadEnabled,
                  }) {
                    givenPort = port;
                    givenAddress = address;
                    givenDartVmServicePort = dartVmServicePort;
                    givenDevServerBundleGenerator = devServerBundleGenerator;
                    givenWorkingDirectory = workingDirectory;
                    givenOnHotReloadEnabled = onHotReloadEnabled;
                    return runner;
                  },
              logger: logger,
            )
            ..testStdin = stdin
            ..testArgResults = argResults
            ..testCwd = cwd;

      await expectLater(command.run(), completion(ExitCode.success.code));

      verify(
        () => runner.start(any(that: equals(['--enable-experiment=macros']))),
      ).called(1);

      expect(givenPort, equals('1234'));
      expect(givenAddress, InternetAddress.tryParse('192.168.1.2'));
      expect(givenDartVmServicePort, equals('5678'));
      expect(givenDevServerBundleGenerator, same(generator));
      expect(givenWorkingDirectory, same(cwd));
      expect(givenOnHotReloadEnabled, isNotNull);
    });

    test('results with dev server exit code', () async {
      final command =
          DevCommand(
              generator: (_) async => generator,
              devServerRunnerConstructor:
                  ({
                    required logger,
                    required port,
                    required address,
                    required devServerBundleGenerator,
                    required dartVmServicePort,
                    required workingDirectory,
                    void Function()? onHotReloadEnabled,
                  }) {
                    return runner;
                  },
              logger: logger,
            )
            ..testArgResults = argResults
            ..testStdin = stdin;

      when(() => runner.start(any())).thenAnswer((_) => Future.value());
      when(() => runner.exitCode).thenAnswer((_) async => ExitCode.unavailable);

      await expectLater(command.run(), completion(ExitCode.unavailable.code));
    });

    test('fails if dev server runner fails on start', () async {
      final command =
          DevCommand(
              generator: (_) async => generator,
              devServerRunnerConstructor:
                  ({
                    required logger,
                    required port,
                    required address,
                    required devServerBundleGenerator,
                    required dartVmServicePort,
                    required workingDirectory,
                    void Function()? onHotReloadEnabled,
                  }) {
                    return runner;
                  },
              logger: logger,
            )
            ..testArgResults = argResults
            ..testStdin = stdin;

      when(() => runner.start(any())).thenAnswer((_) async {
        throw DartFrogDevServerException('oops');
      });

      await expectLater(command.run(), completion(ExitCode.software.code));
      verify(() => logger.err('oops')).called(1);
    });

    test('fails if hostname is invalid', () async {
      when(() => runner.start(any())).thenAnswer((_) => Future.value());
      when(
        () => runner.exitCode,
      ).thenAnswer((_) => Future.value(ExitCode.success));

      when(() => argResults['hostname']).thenReturn('ticarica');
      when(() => argResults['port']).thenReturn('1234');
      when(() => argResults['dart-vm-service-port']).thenReturn('5678');

      final cwd = Directory.systemTemp;

      final command =
          DevCommand(
              generator: (_) async => generator,
              devServerRunnerConstructor:
                  ({
                    required logger,
                    required port,
                    required address,
                    required devServerBundleGenerator,
                    required dartVmServicePort,
                    required workingDirectory,
                    void Function()? onHotReloadEnabled,
                  }) {
                    return runner;
                  },
              logger: logger,
            )
            ..testStdin = stdin
            ..testArgResults = argResults
            ..testCwd = cwd;

      await expectLater(command.run(), completion(ExitCode.software.code));

      verify(
        () => logger.err(
          'Invalid hostname "ticarica": must be a valid IPv4 or IPv6 address.',
        ),
      ).called(1);

      verifyNever(() => runner.start(any()));
    });

    group('listening to stdin', () {
      late Stdin stdin;
      late StreamController<List<int>> stdinController;
      late DevCommand command;
      late void Function() givenOnHotReloadEnabled;
      late Completer<ExitCode> exitCodeCompleter;

      setUp(() {
        stdin = _MockStdin();
        exitCodeCompleter = Completer<ExitCode>();

        when(() => stdin.hasTerminal).thenReturn(true);

        stdinController = StreamController<List<int>>();
        addTearDown(() {
          stdinController.close();
        });

        when(
          () => stdin.listen(
            any(),
            onError: any(named: 'onError'),
            onDone: any(named: 'onDone'),
            cancelOnError: any(named: 'cancelOnError'),
          ),
        ).thenAnswer(
          (invocation) => stdinController.stream.listen(
            invocation.positionalArguments.first as void Function(List<int>),
            onError: invocation.namedArguments[#onError] as Function?,
            onDone: invocation.namedArguments[#onDone] as void Function()?,
            cancelOnError: invocation.namedArguments[#cancelOnError] as bool?,
          ),
        );

        when(() => runner.start(any())).thenAnswer((_) => Future.value());

        when(() => runner.reload()).thenAnswer((_) => Future.value());
        when(() => runner.exitCode).thenAnswer((_) => exitCodeCompleter.future);

        command =
            DevCommand(
                generator: (_) async => generator,
                devServerRunnerConstructor:
                    ({
                      required logger,
                      required port,
                      required address,
                      required devServerBundleGenerator,
                      required dartVmServicePort,
                      required workingDirectory,
                      void Function()? onHotReloadEnabled,
                    }) {
                      givenOnHotReloadEnabled = onHotReloadEnabled!;
                      return runner;
                    },
                logger: logger,
              )
              ..testArgResults = argResults
              ..testStdin = stdin;
      });

      Future<void> hotReloadTest(int asciiValue, String character) async {
        command.run().ignore();
        await Future<void>.delayed(Duration.zero);

        verifyNever(
          () => stdin.listen(
            any(),
            onError: any(named: 'onError'),
            onDone: any(named: 'onDone'),
            cancelOnError: true,
          ),
        );
        verifyNever(() => logger.info('Press $character to reload'));

        givenOnHotReloadEnabled();

        verifyNever(() => runner.reload());
        verify(
          () => stdin.listen(
            any(),
            onError: any(named: 'onError'),
            onDone: any(named: 'onDone'),
            cancelOnError: true,
          ),
        ).called(1);

        verify(() => logger.info('Press either R or r to reload')).called(1);

        verify(() => stdin.echoMode = false).called(1);
        verify(() => stdin.lineMode = false).called(1);

        stdinController.add([42]);
        await Future<void>.delayed(Duration.zero);

        verifyNever(() => runner.reload());

        stdinController.add([asciiValue, 42]);
        await Future<void>.delayed(Duration.zero);

        verifyNever(() => runner.reload());

        stdinController.add([asciiValue]);
        await Future<void>.delayed(Duration.zero);

        verify(() => runner.reload()).called(1);

        exitCodeCompleter.complete(ExitCode.success);
      }

      test('listens for uppercase R on hot reload enabled', () async {
        await hotReloadTest(82, 'R');
      });

      test('listens for lowercase r on hot reload enabled', () async {
        await hotReloadTest(114, 'r');
      });
      test('cancels subscription when dev server stops', () async {
        command.run().ignore();
        await Future<void>.delayed(Duration.zero);

        givenOnHotReloadEnabled();
        await Future<void>.delayed(Duration.zero);

        exitCodeCompleter.complete(ExitCode.success);
        await Future<void>.delayed(Duration.zero);

        expect(stdinController.hasListener, isFalse);
        verify(() => stdin.echoMode = true).called(1);
        verify(() => stdin.lineMode = true).called(1);
      });

      test('cancels subscription when dev server throws', () async {
        final startCompleter = Completer<void>();
        when(() => runner.start(any())).thenAnswer((_) async {
          await startCompleter.future;
        });

        command.run().ignore();
        await Future<void>.delayed(Duration.zero);

        givenOnHotReloadEnabled();
        await Future<void>.delayed(Duration.zero);

        expect(stdinController.hasListener, isTrue);
        verify(() => stdin.echoMode = false).called(1);
        verify(() => stdin.lineMode = false).called(1);

        startCompleter.completeError(Exception('oops'));
        await Future<void>.delayed(Duration.zero);

        expect(stdinController.hasListener, isFalse);
        verify(() => stdin.echoMode = true).called(1);
        verify(() => stdin.lineMode = true).called(1);
      });

      test('cancels subscription when stdin emits error', () async {
        command.run().ignore();
        await Future<void>.delayed(Duration.zero);

        givenOnHotReloadEnabled();
        await Future<void>.delayed(Duration.zero);

        stdinController.addError(Exception('oops'));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(stdinController.hasListener, isFalse);
        verify(() => stdin.echoMode = true).called(1);
        verify(() => stdin.lineMode = true).called(1);

        exitCodeCompleter.complete(ExitCode.success);
      });
    });
  });
}
