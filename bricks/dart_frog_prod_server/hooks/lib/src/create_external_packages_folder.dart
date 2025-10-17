import 'dart:io';

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:io/io.dart' as io;
import 'package:path/path.dart' as path;

/// Signature of [io.copyPath].
typedef CopyPath = Future<void> Function(String from, String to);

Future<List<String>> createExternalPackagesFolder({
  required Directory projectDirectory,
  required Directory buildDirectory,
  CopyPath copyPath = io.copyPath,
}) async {
  final pathResolver = path.context;
  final pubspecLock = await getPubspecLock(
    projectDirectory.path,
    pathContext: path.context,
  );

  final externalPathDependencies = pubspecLock.packages
      .map(
        (dependency) {
          final pathDescription = dependency.pathDescription;
          if (pathDescription == null) return null;

          final isExternal = !pathResolver.isWithin('', pathDescription.path);
          if (!isExternal) return null;

          return ExternalPathDependency(
            name: dependency.name,
            path: path.join(projectDirectory.path, pathDescription.path),
          );
        },
      )
      .whereType<ExternalPathDependency>()
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
      (externalPathDependency) async {
        final copy = await externalPathDependency.copyTo(
          copyPath: copyPath,
          targetDirectory: Directory(
            pathResolver.join(
              packagesDirectory.path,
              externalPathDependency.name,
            ),
          ),
        );
        overrideResolutionInPubspecOverrides(copy.path);
        return copy;
      },
    ),
  );

  overrideResolutionInPubspecOverrides(buildDirectory.path);
  writeDependencyOverrides(
    projectDirectory: buildDirectory.path,
    overrides: {
      for (final externalDependency in copiedExternalPathDependencies)
        externalDependency.name: {
          'path': path.relative(
            externalDependency.path,
            from: buildDirectory.path,
          ),
        },
    },
  );

  return copiedExternalPathDependencies
      .map((dependency) => dependency.path)
      .toList();
}
