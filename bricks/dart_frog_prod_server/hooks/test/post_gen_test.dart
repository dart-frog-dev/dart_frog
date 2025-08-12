import 'dart:io';

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:mason/mason.dart'
    show ExitCode, HookContext, Logger, Progress, lightCyan;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../post_gen.dart' as post_gen;

class _FakeHookContext extends Fake implements HookContext {
  _FakeHookContext({Logger? logger}) : _logger = logger ?? _MockLogger();

  final Logger _logger;

  var _vars = <String, dynamic>{};

  @override
  Map<String, dynamic> get vars => _vars;

  @override
  set vars(Map<String, dynamic> value) => _vars = value;

  @override
  Logger get logger => _logger;
}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  group('postGen', () {
    late HookContext context;
    late Logger logger;

    const processId = 42;
    final processResult = ProcessResult(
      processId,
      ExitCode.success.code,
      '',
      '',
    );

    setUp(() {
      logger = _MockLogger();
      context = _FakeHookContext(logger: logger);

      when(() => logger.progress(any())).thenReturn(_MockProgress());
    });

    test('run completes', () {
      expect(
        ExitOverrides.runZoned(
          () => post_gen.run(_FakeHookContext(logger: logger)),
        ),
        completes,
      );
    });

    test('runs dart pub get and outputs next steps', () async {
      var processRunnerCallCount = 0;
      final exitCalls = <int>[];

      await post_gen.postGen(
        context,
        runProcess: (
          executable,
          args, {
          String? workingDirectory,
          bool? runInShell,
        }) async {
          processRunnerCallCount++;
          expect(executable, equals('dart'));
          expect(args, equals(['pub', 'get']));
          expect(
            workingDirectory,
            equals(path.join(Directory.current.path, 'build')),
          );
          expect(runInShell, isTrue);
          return processResult;
        },
        exit: exitCalls.add,
      );
      expect(processRunnerCallCount, equals(1));
      expect(exitCalls, isEmpty);
      verify(() => logger.success('Created a production build!')).called(1);
      verify(
        () => logger.info('Start the production server by running:'),
      ).called(1);
      verify(
        () => logger.info('${lightCyan.wrap('dart build/bin/server.dart')}'),
      ).called(1);
      verifyNever(() => logger.err(any()));
    });
  });
}
