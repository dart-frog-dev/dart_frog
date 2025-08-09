import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

/// Opts out of dart workspaces until we can generate per package lockfiles.
void copyWorkspacePubspecLock(
  HookContext context, {
  required String buildDirectory,
  required String workingDirectory,
  required void Function(int exitCode) exit,
}) {
  final workspaceRoot = _getWorkspaceRoot();
  if (workspaceRoot == null) {
    context.logger.err(
      'Unable to determine workspace root for $workingDirectory',
    );
    return exit(1);
  }
  final pubspecLockFile = File(path.join(workspaceRoot.path, 'pubspec.lock'));
  if (!pubspecLockFile.existsSync()) return;

  try {
    pubspecLockFile.copySync(path.join(buildDirectory, 'pubspec.lock'));
  } on Exception catch (error) {
    context.logger.err('$error');
    return exit(1);
  }
}

/// Returns the root directory of the nearest Flutter project.
Directory? _getWorkspaceRoot() {
  final file = _findNearestAncestor(
    where: (path) => _getWorkspaceRootPubspecYaml(cwd: Directory(path)),
  );
  if (file == null || !file.existsSync()) return null;
  return Directory(path.dirname(file.path));
}

/// The workspace root `pubspec.yaml` file for this project.
File? _getWorkspaceRootPubspecYaml({required Directory cwd}) {
  try {
    final pubspecYamlFile = File(path.join(cwd.path, 'pubspec.yaml'));
    if (!pubspecYamlFile.existsSync()) return null;
    final pubspec = Pubspec.parse(pubspecYamlFile.readAsStringSync());
    if (pubspec.workspace?.isEmpty ?? true) return null;
    return pubspecYamlFile;
  } on Exception {
    return null;
  }
}

/// Finds nearest ancestor file
/// relative to the [cwd] that satisfies [where].
File? _findNearestAncestor({
  required File? Function(String path) where,
  Directory? cwd,
}) {
  Directory? prev;
  var dir = cwd ?? Directory.current;
  while (prev?.path != dir.path) {
    final file = where(dir.path);
    if (file?.existsSync() ?? false) return file;
    prev = dir;
    dir = dir.parent;
  }
  return null;
}
