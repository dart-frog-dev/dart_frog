import 'dart:io' as io;

import 'package:dart_frog_cli/src/runtime_compatibility.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';

/// Typedef for [ProdServerBuilder.new].
typedef ProdServerBuilderConstructor =
    ProdServerBuilder Function({
      required Logger logger,
      required String dartVersion,
      required io.Directory workingDirectory,
      required MasonGenerator prodServerBundleGenerator,
    });

/// {@template prod_server_builder}
/// A class that builds the production server runtime code.
///
/// This class is responsible for:
///  - Ensuring that the current version of `package:dart_frog` is compatible
///    with the generated code.
///  - Generating the production server runtime code.
///
/// {@endtemplate}
class ProdServerBuilder {
  /// {@macro prod_server_builder}
  ProdServerBuilder({
    required this.logger,
    required this.dartVersion,
    required this.workingDirectory,
    required this.prodServerBundleGenerator,
    @visibleForTesting
    RuntimeCompatibilityCallback? runtimeCompatibilityCallback,
  }) : _ensureRuntimeCompatibility =
           runtimeCompatibilityCallback ?? ensureRuntimeCompatibility;

  /// The Dart SDK version used to build the Dockerfile.
  final String dartVersion;

  /// [Logger] instance used to wrap stdout.
  final Logger logger;

  /// The working directory of the dart_frog project.
  final io.Directory workingDirectory;

  /// The [MasonGenerator] used to generate the prod server runtime code.
  final MasonGenerator prodServerBundleGenerator;

  final RuntimeCompatibilityCallback _ensureRuntimeCompatibility;

  /// Builds the production server runtime code.
  Future<ExitCode> build() async {
    _ensureRuntimeCompatibility(workingDirectory);

    var vars = <String, dynamic>{'dartVersion': dartVersion};

    logger.detail('[codegen] running pre-gen...');
    await prodServerBundleGenerator.hooks.preGen(
      vars: vars,
      workingDirectory: workingDirectory.path,
      onVarsChanged: (v) => vars = v,
    );

    logger.detail('[codegen] running generate...');
    await prodServerBundleGenerator.generate(
      DirectoryGeneratorTarget(workingDirectory),
      vars: vars,
      fileConflictResolution: FileConflictResolution.overwrite,
    );

    logger.detail('[codegen] running post-gen...');
    await prodServerBundleGenerator.hooks.postGen(
      workingDirectory: workingDirectory.path,
    );

    logger.detail('[codegen] complete.');

    return ExitCode.success;
  }
}
