import 'dart:io';

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:io/io.dart' as io;

/// {@template path_dependency}
/// A path dependency that the Dart Frog project relies on.
///
/// For example:
/// ```yaml
/// name: my_dart_frog_project
/// dependencies:
///   my_package:
///     path: ./my_package
/// ```
/// {@endtemplate}
class PathDependency {
  /// {@macro path_dependency}
  const PathDependency({required this.name, required this.path});

  /// The name of the package.
  final String name;

  /// The absolute path to the package.
  final String path;
}

/// {@template external_path_dependency}
/// A path dependency that is not within the bundled Dart Frog project
/// directory.
///
/// For example:
/// ```yaml
/// name: my_dart_frog_project
/// dependencies:
///   my_package:
///     path: ../my_package
/// ```
/// {@endtemplate}
class ExternalPathDependency extends PathDependency {
  /// {@macro external_path_dependency}
  const ExternalPathDependency({required super.name, required super.path});

  /// Copies the [ExternalPathDependency] to [targetDirectory].
  Future<ExternalPathDependency> copyTo({
    required Directory targetDirectory,
    CopyPath copyPath = io.copyPath,
  }) async {
    await copyPath(path, targetDirectory.path);
    return ExternalPathDependency(name: name, path: targetDirectory.path);
  }
}
