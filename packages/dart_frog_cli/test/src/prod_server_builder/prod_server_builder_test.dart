import 'dart:io';

import 'package:dart_frog_cli/src/prod_server_builder/prod_server_builder.dart';
import 'package:dart_frog_cli/src/runtime_compatibility.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockGeneratorHooks extends Mock implements GeneratorHooks {}

class _MockProgress extends Mock implements Progress {}

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDirectoryGeneratorTarget());
  });

  late Logger logger;
  late Progress progress;
  late MasonGenerator generator;

  setUp(() {
    logger = _MockLogger();
    progress = _MockProgress();
    when(() => logger.progress(any())).thenReturn(progress);
    generator = _MockMasonGenerator();
  });

  group('$ProdServerBuilder', () {
    test('can be instantiated', () {
      expect(
        ProdServerBuilder(
          logger: logger,
          prodServerBundleGenerator: generator,
          dartVersion: 'stable',
          workingDirectory: Directory.current,
        ),
        isNotNull,
      );
    });

    group('build', () {
      test('throws if ensureRuntimeCompatibility fails', () {
        final builder = ProdServerBuilder(
          logger: logger,
          dartVersion: 'stable',
          workingDirectory: Directory.current,
          prodServerBundleGenerator: generator,
          runtimeCompatibilityCallback: (_) {
            throw const DartFrogCompatibilityException('oops');
          },
        );
        expect(builder.build, throwsA(isA<DartFrogCompatibilityException>()));
      });

      test('generates a build successfully.', () async {
        final generatorHooks = _MockGeneratorHooks();
        when(
          () => generatorHooks.preGen(
            vars: {'dartVersion': 'stable'},
            workingDirectory: any(named: 'workingDirectory'),
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        ).thenAnswer((invocation) async {
          (invocation.namedArguments[const Symbol('onVarsChanged')]
                  as void Function(Map<String, dynamic>))
              .call({'dartVersion': 'stable'});
        });
        when(
          () => generator.generate(
            any(),
            vars: {'dartVersion': 'stable'},
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).thenAnswer((_) async => []);
        when(
          () => generatorHooks.postGen(
            vars: any(named: 'vars'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async {});
        when(() => generator.hooks).thenReturn(generatorHooks);
        final builder = ProdServerBuilder(
          logger: logger,
          prodServerBundleGenerator: generator,
          dartVersion: 'stable',
          workingDirectory: Directory.current,
          runtimeCompatibilityCallback: (_) {},
        );
        final exitCode = await builder.build();
        expect(exitCode, equals(ExitCode.success));
      });
    });
  });
}
