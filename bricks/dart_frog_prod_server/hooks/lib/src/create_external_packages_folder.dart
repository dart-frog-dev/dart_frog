import 'dart:io';

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:io/io.dart' as io;
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

/// Signature of [io.copyPath].
typedef CopyPath = Future<void> Function(String from, String to);

Future<List<String>> createExternalPackagesFolder({
  required Directory projectDirectory,
  required Directory buildDirectory,
  CopyPath copyPath = io.copyPath,
}) async {
  final pathResolver = path.context;
  final pubspec = await getPubspec(
    projectDirectory.path,
    pathContext: path.context,
  );

  final externalPathDependencies = pubspec.dependencies.values
      .map(
        (dependency) {
          if (dependency is! PathDependency) return null;
          if (pathResolver.isWithin('', dependency.path)) return null;

          return _ExternalPathDependency(
            name: path.basenameWithoutExtension(dependency.path),
            path: path.join(projectDirectory.path, dependency.path),
          );
        },
      )
      .whereType<_ExternalPathDependency>()
      .toList();

  if (externalPathDependencies.isEmpty) return [];

  final packagesDirectory = Directory(
    pathResolver.join(
      buildDirectory.path,
      '.dart_frog_path_dependencies',
    ),
  )..createSync(recursive: true);

  final copiedExternalPathDependencies = await Future.wait(
    externalPathDependencies.map(
      (externalPathDependency) => externalPathDependency.copyTo(
        copyPath: copyPath,
        targetDirectory: Directory(
          pathResolver.join(
            packagesDirectory.path,
            externalPathDependency.name,
          ),
        ),
      ),
    ),
  );

  await File(
    pathResolver.join(
      buildDirectory.path,
      'pubspec_overrides.yaml',
    ),
  ).writeAsString(
    '''
dependency_overrides:
${copiedExternalPathDependencies.map(
      (dependency) {
        final name = dependency.name;
        final path =
            pathResolver.relative(dependency.path, from: buildDirectory.path);
        return '  $name:\n    path: $path';
      },
    ).join('\n')}
''',
    mode: FileMode.append,
  );

  return copiedExternalPathDependencies
      .map((dependency) => dependency.path)
      .toList();
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
class _ExternalPathDependency {
  /// {@macro external_path_dependency}
  const _ExternalPathDependency({
    required this.name,
    required this.path,
  });

  /// The name of the package.
  final String name;

  /// The absolute path to the package.
  final String path;

  /// Copies the [_ExternalPathDependency] to [targetDirectory].
  Future<_ExternalPathDependency> copyTo({
    required Directory targetDirectory,
    CopyPath copyPath = io.copyPath,
  }) async {
    await copyPath(path, targetDirectory.path);
    return _ExternalPathDependency(name: name, path: targetDirectory.path);
  }
}
