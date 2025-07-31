import 'dart:async';
import 'dart:convert';
import 'dart:io' hide exitCode;

import 'package:dart_frog_cli/src/dev_server_runner/dev_server_runner.dart';
import 'package:dart_frog_cli/src/dev_server_runner/restorable_directory_generator_target.dart';
import 'package:dart_frog_cli/src/runtime_compatibility.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

class _MockDirectoryWatcher extends Mock implements DirectoryWatcher {}

class _MockLogger extends Mock implements Logger {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockGeneratorHooks extends Mock implements GeneratorHooks {}

class _MockProcess extends Mock implements Process {}

class _MockProcessSignal extends Mock implements ProcessSignal {}

class _MockProgress extends Mock implements Progress {}

class _MockRestorableDirectoryGeneratorTarget extends Mock
    implements RestorableDirectoryGeneratorTarget {}

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDirectoryGeneratorTarget());
  });

  const port = '8080';
  const dartVmServicePort = '8081';

  const processId = 42;
  final processResult = ProcessResult(processId, 0, '', '');

  late Logger logger;
  late DirectoryWatcher directoryWatcher;
  late MasonGenerator generator;
  late bool isWindows;
  late Progress progress;
  late Process process;
  late ProcessSignal sigint;
  late RestorableDirectoryGeneratorTarget generatorTarget;
  late GeneratorHooks generatorHooks;

  late DevServerRunner devServerRunner;

  setUp(() {
    logger = _MockLogger();
    directoryWatcher = _MockDirectoryWatcher();
    generator = _MockMasonGenerator();
    process = _MockProcess();
    generatorTarget = _MockRestorableDirectoryGeneratorTarget();
    isWindows = false;
    sigint = _MockProcessSignal();
    progress = _MockProgress();

    when(() => logger.progress(any())).thenReturn(progress);

    when(() => directoryWatcher.events).thenAnswer((_) => const Stream.empty());
    when(process.kill).thenAnswer((invocation) => true);
    final completer = Completer<int>();
    when(() => process.exitCode).thenAnswer((_) => completer.future);

    devServerRunner = DevServerRunner(
      logger: logger,
      port: port,
      address: null,
      devServerBundleGenerator: generator,
      dartVmServicePort: dartVmServicePort,
      workingDirectory: Directory.current,
      directoryWatcher: (_) => directoryWatcher,
      generatorTarget: (_, {createFile, logger}) => generatorTarget,
      isWindows: isWindows,
      startProcess: (_, __, {runInShell = false}) async => process,
      sigint: sigint,
      runProcess: (_, __) async => processResult,
      runtimeCompatibilityCallback: (_) {},
    );

    when(() => process.stdout).thenAnswer((_) => const Stream.empty());
    when(() => process.stderr).thenAnswer((_) => const Stream.empty());

    generatorHooks = _MockGeneratorHooks();

    when(
      () => generatorHooks.preGen(
        vars: any(named: 'vars'),
        workingDirectory: any(named: 'workingDirectory'),
        onVarsChanged: any(named: 'onVarsChanged'),
      ),
    ).thenAnswer((invocation) async {
      (invocation.namedArguments[const Symbol('onVarsChanged')]
              as void Function(Map<String, dynamic> vars))
          .call(<String, dynamic>{});
    });

    when(
      () => generator.generate(
        any(),
        vars: any(named: 'vars'),
        fileConflictResolution: FileConflictResolution.overwrite,
      ),
    ).thenAnswer((_) async => []);
    when(() => generator.hooks).thenReturn(generatorHooks);
    when(() => process.pid).thenReturn(processId);
  });

  group('$DevServerRunner', () {
    test('can be instantiated', () {
      expect(
        DevServerRunner(
          logger: Logger(),
          port: '8080',
          address: null,
          devServerBundleGenerator: _MockMasonGenerator(),
          dartVmServicePort: '8081',
          workingDirectory: Directory.current,
        ),
        isNotNull,
      );
    });

    group('start', () {
      test('starts a dev server successfully.', () async {
        when(() => directoryWatcher.events).thenAnswer(
          (_) => Stream.value(WatchEvent(ChangeType.MODIFY, 'README.md')),
        );

        await expectLater(devServerRunner.start(), completes);

        expect(devServerRunner.isWatching, isTrue);
        expect(devServerRunner.isServerRunning, isTrue);
        expect(devServerRunner.isCompleted, isFalse);
        verify(
          () => generatorHooks.preGen(
            vars: <String, dynamic>{'port': '8080'},
            workingDirectory: any(named: 'workingDirectory'),
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        ).called(1);

        verify(() {
          progress.complete(
            'Running on ${link(uri: Uri.parse('http://localhost:8080'))}',
          );
        }).called(1);
      });

      test('throws if ensureRuntimeCompatibility fails', () async {
        devServerRunner = DevServerRunner(
          logger: logger,
          port: port,
          address: null,
          devServerBundleGenerator: generator,
          dartVmServicePort: dartVmServicePort,
          workingDirectory: Directory.current,
          directoryWatcher: (_) => directoryWatcher,
          generatorTarget: (_, {createFile, logger}) => generatorTarget,
          isWindows: isWindows,
          startProcess: (_, __, {runInShell = false}) async => process,
          sigint: sigint,
          runProcess: (_, __) async => processResult,
          runtimeCompatibilityCallback: (_) {
            throw const DartFrogCompatibilityException('oops');
          },
        );

        await expectLater(
          devServerRunner.start(),
          throwsA(
            isA<DartFrogCompatibilityException>().having(
              (e) => e.message,
              'message',
              'oops',
            ),
          ),
        );
      });

      test('throws when server process is already running', () async {
        await expectLater(devServerRunner.start(), completes);

        await expectLater(
          devServerRunner.start(),
          throwsA(
            isA<DartFrogDevServerException>().having(
              (e) => e.message,
              'message',
              'Cannot start a dev server while already running.',
            ),
          ),
        );
      });

      test('throws when dev server has been completed', () async {
        await expectLater(devServerRunner.start(), completes);

        await devServerRunner.exitCode;

        await expectLater(
          devServerRunner.start(),
          throwsA(
            isA<DartFrogDevServerException>().having(
              (e) => e.message,
              'message',
              'Cannot start a dev server after it has been stopped.',
            ),
          ),
        );
      });

      test('custom port numbers', () async {
        late List<String> receivedArgs;

        devServerRunner = DevServerRunner(
          logger: logger,
          port: '4242',
          address: null,
          devServerBundleGenerator: generator,
          dartVmServicePort: '4343',
          workingDirectory: Directory.current,
          directoryWatcher: (_) => directoryWatcher,
          generatorTarget: (_, {createFile, logger}) => generatorTarget,
          isWindows: isWindows,
          startProcess:
              (
                String executable,
                List<String> arguments, {
                bool runInShell = false,
              }) async {
                receivedArgs = arguments;
                return process;
              },
          sigint: sigint,
          runProcess: (_, __) async => processResult,
          runtimeCompatibilityCallback: (_) => true,
        );

        await expectLater(devServerRunner.start(), completes);

        expect(devServerRunner.isWatching, isTrue);
        expect(devServerRunner.isServerRunning, isTrue);
        expect(devServerRunner.isCompleted, isFalse);

        expect(receivedArgs, contains('--enable-vm-service=4343'));
        verify(
          () => generatorHooks.preGen(
            vars: <String, dynamic>{'port': '4242'},
            workingDirectory: any(named: 'workingDirectory'),
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        ).called(1);

        verify(() {
          progress.complete(
            'Running on ${link(uri: Uri.parse('http://localhost:4242'))}',
          );
        }).called(1);
      });

      test('custom address', () async {
        late List<String> receivedArgs;

        devServerRunner = DevServerRunner(
          logger: logger,
          port: '4242',
          address: InternetAddress.tryParse('192.162.1.2'),
          devServerBundleGenerator: generator,
          dartVmServicePort: '4343',
          workingDirectory: Directory.current,
          directoryWatcher: (_) => directoryWatcher,
          generatorTarget: (_, {createFile, logger}) => generatorTarget,
          isWindows: isWindows,
          startProcess:
              (
                String executable,
                List<String> arguments, {
                bool runInShell = false,
              }) async {
                receivedArgs = arguments;
                return process;
              },
          sigint: sigint,
          runProcess: (_, __) async => processResult,
          runtimeCompatibilityCallback: (_) => true,
        );

        await expectLater(devServerRunner.start(), completes);

        expect(devServerRunner.isWatching, isTrue);
        expect(devServerRunner.isServerRunning, isTrue);
        expect(devServerRunner.isCompleted, isFalse);

        expect(receivedArgs, contains('--enable-vm-service=4343'));
        verify(
          () => generatorHooks.preGen(
            vars: <String, dynamic>{'port': '4242', 'host': '192.162.1.2'},
            workingDirectory: any(named: 'workingDirectory'),
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        ).called(1);

        verify(() {
          progress.complete(
            'Running on ${link(uri: Uri.parse('http://192.162.1.2:4242'))}',
          );
        }).called(1);
      });

      test(
        'kills process if error occurs before hot reload is enabled on windows',
        () async {
          final processRunCalls = <List<String>>[];
          when(
            () => process.stderr,
          ).thenAnswer((_) => Stream.value(utf8.encode('oops')));

          when(
            () => directoryWatcher.events,
          ).thenAnswer((_) => StreamController<WatchEvent>().stream);
          when(() => sigint.watch()).thenAnswer((_) => const Stream.empty());
          devServerRunner = DevServerRunner(
            logger: logger,
            port: port,
            address: null,
            devServerBundleGenerator: generator,
            dartVmServicePort: dartVmServicePort,
            workingDirectory: Directory.current,
            directoryWatcher: (_) => directoryWatcher,
            isWindows: true,
            startProcess: (_, __, {runInShell = false}) async => process,
            sigint: sigint,
            runProcess: (String executable, List<String> arguments) async {
              processRunCalls.add([executable, ...arguments]);
              return processResult;
            },
            runtimeCompatibilityCallback: (_) => true,
          );
          await expectLater(devServerRunner.start(), completes);

          final exitCode = await devServerRunner.exitCode;

          expect(devServerRunner.isWatching, isFalse);
          expect(devServerRunner.isServerRunning, isFalse);
          expect(devServerRunner.isCompleted, isTrue);
          expect(exitCode.code, 70);
          expect(
            processRunCalls,
            equals([
              ['taskkill', '/F', '/T', '/PID', '$processId'],
            ]),
          );
          verifyNever(() => process.kill());
        },
      );

      test('logs process.stdout', () async {
        when(() => process.stdout).thenAnswer(
          (_) => Stream.fromIterable([
            utf8.encode('  Message A  '),
            utf8.encode(''),
            utf8.encode(' Message B'),
            utf8.encode(' '),
            utf8.encode('Message C '),
            utf8.encode('  '),
            utf8.encode('Message D'),
          ]),
        );
        when(
          () => directoryWatcher.events,
        ).thenAnswer((_) => const Stream.empty());

        await expectLater(devServerRunner.start(), completes);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        verifyInOrder([
          () => logger.info('Message A'),
          () => logger.info('Message B'),
          () => logger.info('Message C'),
          () => logger.info('Message D'),
        ]);
      });
    });

    group('reload and codegen', () {
      test('reloads successfully when .reload is called', () async {
        await expectLater(devServerRunner.start(), completes);

        verify(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);

        await devServerRunner.reload();

        verify(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);
      });

      test('does not reload when dev server is completed', () async {
        await expectLater(devServerRunner.start(), completes);

        verify(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);

        await expectLater(devServerRunner.stop(), completes);

        await devServerRunner.reload();

        verifyNever(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        );
      });

      test('does not reload when dev server is not running ', () async {
        await devServerRunner.reload();

        verifyNever(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        );
      });

      test('enable asserts', () async {
        final generatorHooks = _MockGeneratorHooks();
        when(
          () => generatorHooks.preGen(
            vars: any(named: 'vars'),
            workingDirectory: any(named: 'workingDirectory'),
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        ).thenAnswer((invocation) async {
          (invocation.namedArguments[const Symbol('onVarsChanged')]
                  as void Function(Map<String, dynamic> vars))
              .call(<String, dynamic>{});
        });
        when(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).thenAnswer((_) async => []);
        when(() => generator.hooks).thenReturn(generatorHooks);
        when(() => process.stdout).thenAnswer((_) => const Stream.empty());
        when(() => process.stderr).thenAnswer((_) => const Stream.empty());
        when(() => directoryWatcher.events).thenAnswer(
          (_) => Stream.value(WatchEvent(ChangeType.MODIFY, 'README.md')),
        );

        late List<String> receivedArgs;
        devServerRunner = DevServerRunner(
          logger: logger,
          port: '4242',
          address: null,
          devServerBundleGenerator: generator,
          dartVmServicePort: '4343',
          workingDirectory: Directory.current,
          directoryWatcher: (_) => directoryWatcher,
          generatorTarget: (_, {CreateFile? createFile, Logger? logger}) =>
              generatorTarget,
          isWindows: isWindows,
          startProcess:
              (
                String executable,
                List<String> arguments, {
                bool runInShell = false,
              }) async {
                receivedArgs = arguments;
                return process;
              },
          sigint: sigint,
          runProcess: (_, __) async => processResult,
          runtimeCompatibilityCallback: (_) => true,
        );
        await expectLater(devServerRunner.start(), completes);

        expect(receivedArgs, contains('--enable-asserts'));
      });

      test('does not reload when reloading ', () async {
        await expectLater(devServerRunner.start(), completes);

        verify(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);

        final reloadFuture = devServerRunner.reload();

        devServerRunner.reload().ignore();

        verifyNever(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        );

        await reloadFuture;

        verify(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);
      });

      test('completes dev server when watcher ends', () async {
        final controller = StreamController<WatchEvent>();
        when(() => process.stdout).thenAnswer(
          (_) => Stream.value(utf8.encode('[hotreload] hot reload enabled.')),
        );
        when(
          () => directoryWatcher.events,
        ).thenAnswer((_) => controller.stream);
        await expectLater(devServerRunner.start(), completes);

        expect(devServerRunner.isWatching, isTrue);
        expect(devServerRunner.isServerRunning, isTrue);
        expect(devServerRunner.isCompleted, isFalse);

        await controller.close();
        await Future<void>.delayed(Duration.zero);

        expect(devServerRunner.isWatching, isFalse);
        expect(devServerRunner.isServerRunning, isFalse);
        expect(devServerRunner.isCompleted, isTrue);
        await expectLater(
          devServerRunner.exitCode,
          completion(ExitCode.success),
        );
      });

      test('completes dev server when watcher ends with error', () async {
        final controller = StreamController<WatchEvent>();
        when(() => process.stdout).thenAnswer(
          (_) => Stream.value(utf8.encode('[hotreload] hot reload enabled.')),
        );
        when(
          () => directoryWatcher.events,
        ).thenAnswer((_) => controller.stream);
        await expectLater(devServerRunner.start(), completes);

        expect(devServerRunner.isWatching, isTrue);
        expect(devServerRunner.isServerRunning, isTrue);
        expect(devServerRunner.isCompleted, isFalse);

        controller.addError(Exception('error'));
        await Future<void>.delayed(Duration.zero);

        expect(devServerRunner.isWatching, isFalse);
        expect(devServerRunner.isServerRunning, isFalse);
        expect(devServerRunner.isCompleted, isTrue);
        await expectLater(
          devServerRunner.exitCode,
          completion(ExitCode.software),
        );
      });

      test(
        '''
runs codegen with debounce when changes are made to the public or routes directory''',
        () async {
          final controller = StreamController<WatchEvent>();
          when(() => process.stdout).thenAnswer(
            (_) => Stream.value(utf8.encode('[hotreload] hot reload enabled.')),
          );
          when(
            () => directoryWatcher.events,
          ).thenAnswer((_) => controller.stream);

          await expectLater(devServerRunner.start(), completes);

          await Future<void>.delayed(const Duration(milliseconds: 100));

          verify(
            () => generator.generate(
              any(),
              vars: any(named: 'vars'),
              fileConflictResolution: FileConflictResolution.overwrite,
            ),
          ).called(1);

          controller
            ..add(
              WatchEvent(
                ChangeType.ADD,
                path.join(Directory.current.path, 'routes', 'users.dart'),
              ),
            )
            ..add(
              WatchEvent(
                ChangeType.REMOVE,
                path.join(Directory.current.path, 'routes', 'user.dart'),
              ),
            );

          await Future<void>.delayed(const Duration(milliseconds: 100));

          verify(
            () => generator.generate(
              any(),
              vars: any(named: 'vars'),
              fileConflictResolution: FileConflictResolution.overwrite,
            ),
          ).called(1);

          controller.add(
            WatchEvent(
              ChangeType.MODIFY,
              path.join(Directory.current.path, 'public', 'hello.txt'),
            ),
          );

          await Future<void>.delayed(const Duration(milliseconds: 100));

          verify(
            () => generator.generate(
              any(),
              vars: any(named: 'vars'),
              fileConflictResolution: FileConflictResolution.overwrite,
            ),
          ).called(1);

          controller.add(
            WatchEvent(
              ChangeType.MODIFY,
              path.join(Directory.current.path, 'tmp', 'message.txt'),
            ),
          );

          await Future<void>.delayed(const Duration(milliseconds: 100));
          verifyNever(
            () => generator.generate(
              any(),
              vars: any(named: 'vars'),
              fileConflictResolution: FileConflictResolution.overwrite,
            ),
          );
        },
      );

      test('runs codegen when changes are made to main.dart', () async {
        final controller = StreamController<WatchEvent>();
        when(() => process.stdout).thenAnswer(
          (_) => Stream.value(utf8.encode('[hotreload] hot reload enabled.')),
        );
        when(
          () => directoryWatcher.events,
        ).thenAnswer((_) => controller.stream);

        await expectLater(devServerRunner.start(), completes);

        verify(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);

        controller.add(
          WatchEvent(
            ChangeType.ADD,
            path.join(Directory.current.path, 'main.dart'),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        verify(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);
      });

      test('runs codegen when changes are made to pubspec.yaml', () async {
        final controller = StreamController<WatchEvent>();

        when(() => process.stdout).thenAnswer(
          (_) => Stream.value(utf8.encode('[hotreload] hot reload enabled.')),
        );

        when(
          () => directoryWatcher.events,
        ).thenAnswer((_) => controller.stream);

        await expectLater(devServerRunner.start(), completes);

        verify(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);

        controller.add(
          WatchEvent(
            ChangeType.MODIFY,
            path.join(Directory.current.path, 'pubspec.yaml'),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        verify(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);
      });

      test('caches snapshot when hot reload runs successfully', () async {
        when(() => process.stdout).thenAnswer(
          (_) => Stream.value(utf8.encode('[hotreload] hot reload enabled.')),
        );

        await expectLater(devServerRunner.start(), completes);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        verify(() => generatorTarget.cacheLatestSnapshot()).called(1);
      });

      test('restores previous snapshot when hot reload fails.', () async {
        final stdoutController = StreamController<List<int>>();
        final stderrController = StreamController<List<int>>();

        when(() => generatorTarget.rollback()).thenAnswer((_) async {});
        when(() => process.stdout).thenAnswer((_) => stdoutController.stream);
        when(() => process.stderr).thenAnswer((_) => stderrController.stream);

        await expectLater(devServerRunner.start(), completes);

        stdoutController.add(utf8.encode('[hotreload] hot reload enabled'));
        await untilCalled(() => generatorTarget.cacheLatestSnapshot());

        const error = 'something went wrong';

        stderrController.add(utf8.encode(error));
        await untilCalled(() => generatorTarget.rollback());

        await stderrController.close();
        await stdoutController.close();

        verify(() => generatorTarget.cacheLatestSnapshot()).called(1);
        verify(() => generatorTarget.rollback()).called(1);
        verify(() => logger.err(error)).called(1);
      });
    });

    group('process runtime', () {
      test(
        'kills all child processes when sigint received on windows',
        () async {
          final processRunCalls = <List<String>>[];

          when(
            () => directoryWatcher.events,
          ).thenAnswer((_) => StreamController<WatchEvent>().stream);
          when(() => sigint.watch()).thenAnswer((_) => Stream.value(sigint));

          devServerRunner = DevServerRunner(
            logger: logger,
            port: port,
            address: null,
            devServerBundleGenerator: generator,
            dartVmServicePort: dartVmServicePort,
            workingDirectory: Directory.current,
            directoryWatcher: (_) => directoryWatcher,
            isWindows: true,
            startProcess: (_, __, {runInShell = false}) async => process,
            sigint: sigint,
            runProcess: (String executable, List<String> arguments) async {
              processRunCalls.add([executable, ...arguments]);
              return processResult;
            },
            runtimeCompatibilityCallback: (_) => true,
          );

          await expectLater(devServerRunner.start(), completes);

          await untilCalled(() => process.pid);
          final exitCode = await devServerRunner.exitCode;

          expect(exitCode.code, equals(0));
          expect(
            processRunCalls,
            equals([
              ['taskkill', '/F', '/T', '/PID', '$processId'],
            ]),
          );
          verifyNever(() => process.kill());
        },
      );

      test(
        'completes dev server if server process is killed externally',
        () async {
          final completer = Completer<int>();
          when(() => process.exitCode).thenAnswer((_) => completer.future);

          final controller = StreamController<WatchEvent>();
          when(
            () => directoryWatcher.events,
          ).thenAnswer((_) => controller.stream);

          await expectLater(devServerRunner.start(), completes);

          completer.complete(0);
          await Future<void>.delayed(Duration.zero);

          verify(
            () => logger.info('[process] Server process has been terminated'),
          ).called(1);
          verify(() => process.kill()).called(1);
          await expectLater(
            devServerRunner.exitCode,
            completion(ExitCode.unavailable),
          );
        },
      );

      test('completes dev server when watcher is finished', () async {
        final completer = Completer<int>();
        when(() => process.exitCode).thenAnswer((_) => completer.future);

        final controller = StreamController<WatchEvent>();
        when(
          () => directoryWatcher.events,
        ).thenAnswer((_) => controller.stream);

        await expectLater(devServerRunner.start(), completes);
        await controller.close();
        await Future<void>.delayed(Duration.zero);

        expect(devServerRunner.isCompleted, isTrue);

        completer.complete(0);
        await Future<void>.delayed(Duration.zero);

        verifyNever(
          () => logger.info('[process] server process has been terminated'),
        );
        await expectLater(
          devServerRunner.exitCode,
          completion(ExitCode.success),
        );
      });

      test(
        '''kills process if error occurs before hot reload is enabled on non-windows''',
        () async {
          final processRunCalls = <List<String>>[];

          when(
            () => process.stderr,
          ).thenAnswer((_) => Stream.value(utf8.encode('oops')));
          when(() => process.kill()).thenReturn(true);
          when(
            () => directoryWatcher.events,
          ).thenAnswer((_) => StreamController<WatchEvent>().stream);
          when(() => sigint.watch()).thenAnswer((_) => const Stream.empty());

          devServerRunner = DevServerRunner(
            logger: logger,
            port: port,
            address: null,
            devServerBundleGenerator: generator,
            dartVmServicePort: dartVmServicePort,
            workingDirectory: Directory.current,
            directoryWatcher: (_) => directoryWatcher,
            startProcess: (_, __, {runInShell = false}) async => process,
            sigint: sigint,
            runProcess: (String executable, List<String> arguments) async {
              processRunCalls.add([executable, ...arguments]);
              return processResult;
            },
            runtimeCompatibilityCallback: (_) => true,
          );

          await expectLater(devServerRunner.start(), completes);
          final exitCode = await devServerRunner.exitCode;

          expect(exitCode.code, equals(70));
          expect(processRunCalls, isEmpty);
          verify(() => process.kill()).called(1);
        },
      );

      test(
        '''
Does not kill process if a warning occurs before hot reload is enabled''',
        () async {
          const warningMessage = """
lib/my_model.g.dart:53:20: Warning: Operand of null-aware operation '!' has type 'String' which excludes null.
          ? _value.name!
                   ^
          """;

          when(
            () => process.stderr,
          ).thenAnswer((_) => Stream.value(utf8.encode(warningMessage)));
          when(() => directoryWatcher.events).thenAnswer(
            (_) => Stream.value(WatchEvent(ChangeType.MODIFY, 'README.md')),
          );
          devServerRunner = DevServerRunner(
            logger: logger,
            port: port,
            address: null,
            devServerBundleGenerator: generator,
            dartVmServicePort: dartVmServicePort,
            workingDirectory: Directory.current,
            directoryWatcher: (_) => directoryWatcher,
            startProcess: (_, __, {runInShell = false}) async => process,
            sigint: sigint,
            runtimeCompatibilityCallback: (_) => true,
          );

          await expectLater(devServerRunner.start(), completes);

          await untilCalled(() => logger.warn(warningMessage.trim()));
          verifyNever(() => process.kill());

          verify(
            () => generatorHooks.preGen(
              vars: <String, dynamic>{'port': '8080'},
              workingDirectory: any(named: 'workingDirectory'),
              onVarsChanged: any(named: 'onVarsChanged'),
            ),
          ).called(1);
        },
      );

      test('kills process with message when Dart VM is already in use', () async {
        final processRunCalls = <List<String>>[];

        const errorMessage = '''
Could not start the VM service: localhost:8181 is already in use.''';
        when(
          () => process.stderr,
        ).thenAnswer((_) => Stream.value(utf8.encode(errorMessage)));
        when(() => process.kill()).thenReturn(true);
        when(
          () => directoryWatcher.events,
        ).thenAnswer((_) => StreamController<WatchEvent>().stream);
        when(() => sigint.watch()).thenAnswer((_) => const Stream.empty());
        devServerRunner = DevServerRunner(
          logger: logger,
          port: port,
          address: null,
          devServerBundleGenerator: generator,
          dartVmServicePort: dartVmServicePort,
          workingDirectory: Directory.current,
          directoryWatcher: (_) => directoryWatcher,
          startProcess: (_, __, {runInShell = false}) async => process,
          sigint: sigint,
          runProcess: (String executable, List<String> arguments) async {
            processRunCalls.add([executable, ...arguments]);
            return processResult;
          },
          runtimeCompatibilityCallback: (_) => true,
        );

        await expectLater(devServerRunner.start(), completes);
        final exitCode = await devServerRunner.exitCode;

        expect(
          exitCode.code,
          equals(70),
          reason: 'Should exit when VM service is already in use.',
        );
        expect(
          processRunCalls,
          isEmpty,
          reason: 'Should not run the serve process.',
        );
        verify(() => process.kill()).called(1);
        verify(
          () => logger.err(
            '$errorMessage '
            '''Try specifying a different port using the `--dart-vm-service-port` argument when running `dart_frog dev`.''',
          ),
        ).called(1);
      });
    });
  });
}
