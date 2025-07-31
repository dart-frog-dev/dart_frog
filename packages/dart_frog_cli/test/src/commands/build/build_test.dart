import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_frog_cli/src/commands/commands.dart';
import 'package:dart_frog_cli/src/prod_server_builder/prod_server_builder.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockArgResults extends Mock implements ArgResults {}

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

class _MockProdServerBuilder extends Mock implements ProdServerBuilder {}

void main() {
  group('dart_frog build', () {
    setUpAll(() {
      registerFallbackValue(_FakeDirectoryGeneratorTarget());
    });

    final cwd = Directory.systemTemp;

    late Logger logger;
    late MasonGenerator generator;
    late ArgResults argResults;
    late ProdServerBuilder builder;

    setUp(() {
      logger = _MockLogger();
      generator = _MockMasonGenerator();
      argResults = _MockArgResults();
      when(() => argResults['dart-version']).thenReturn('stable');
      builder = _MockProdServerBuilder();
    });

    test('can be instantiated', () {
      expect(BuildCommand(logger: logger), isNotNull);
    });

    test('passes the correct params to the builder', () async {
      late String givenDartVersion;
      late Directory givenWorkingDirectory;
      late MasonGenerator givenProdServerBundleGenerator;

      final command =
          BuildCommand(
              logger: logger,
              generator: (_) async => generator,
              prodServerBuilderConstructor:
                  ({
                    required Logger logger,
                    required String dartVersion,
                    required Directory workingDirectory,
                    required MasonGenerator prodServerBundleGenerator,
                  }) {
                    givenDartVersion = dartVersion;
                    givenWorkingDirectory = workingDirectory;
                    givenProdServerBundleGenerator = prodServerBundleGenerator;
                    return builder;
                  },
            )
            ..testArgResults = argResults
            ..testCwd = cwd;
      when(
        () => builder.build(),
      ).thenAnswer((_) => Future.value(ExitCode.tempFail));

      await expectLater(command.run(), completion(ExitCode.tempFail.code));

      verify(() => builder.build()).called(1);

      expect(givenDartVersion, equals('stable'));
      expect(givenWorkingDirectory, same(cwd));
      expect(givenProdServerBundleGenerator, same(generator));
    });

    test('returns software error if the builder throws', () {
      final command =
          BuildCommand(
              logger: logger,
              generator: (_) async => generator,
              prodServerBuilderConstructor:
                  ({
                    required Logger logger,
                    required String dartVersion,
                    required Directory workingDirectory,
                    required MasonGenerator prodServerBundleGenerator,
                  }) => builder,
            )
            ..testArgResults = argResults
            ..testCwd = cwd;

      when(() => builder.build()).thenThrow(Exception());
      expect(command.run(), completion(ExitCode.software.code));
    });
  });
}
