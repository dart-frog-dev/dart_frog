import 'package:dart_frog_cli/src/command.dart';
import 'package:dart_frog_cli/src/commands/build/templates/dart_frog_prod_server_bundle.dart';
import 'package:dart_frog_cli/src/commands/commands.dart';
import 'package:dart_frog_cli/src/prod_server_builder/prod_server_builder.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';

/// {@template build_command}
/// `dart_frog build` command which creates a production build`.
/// {@endtemplate}
class BuildCommand extends DartFrogCommand {
  /// {@macro build_command}
  BuildCommand({
    super.logger,
    @visibleForTesting GeneratorBuilder? generator,
    @visibleForTesting
    ProdServerBuilderConstructor? prodServerBuilderConstructor,
  }) : _generator = generator ?? MasonGenerator.fromBundle,
       _prodServerBuilderConstructor =
           prodServerBuilderConstructor ?? ProdServerBuilder.new {
    argParser.addOption(
      'dart-version',
      defaultsTo: 'stable',
      help:
          'The Dart SDK version used to build the Dockerfile, defaults to'
          ' stable.',
    );
  }

  final GeneratorBuilder _generator;
  final ProdServerBuilderConstructor _prodServerBuilderConstructor;

  @override
  final String description = 'Create a production build.';

  @override
  final String name = 'build';

  @override
  Future<int> run() async {
    final dartVersion = results['dart-version'] as String;
    final generator = await _generator(dartFrogProdServerBundle);

    final builder = _prodServerBuilderConstructor(
      logger: logger,
      dartVersion: dartVersion,
      workingDirectory: cwd,
      prodServerBundleGenerator: generator,
    );

    try {
      return (await builder.build()).code;
    } catch (e) {
      logger.err(e.toString());
      return ExitCode.software.code;
    }
  }
}
