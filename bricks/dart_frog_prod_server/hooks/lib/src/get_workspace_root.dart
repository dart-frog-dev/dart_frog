import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Returns the root directory of the nearest Dart workspace.
Directory? getWorkspaceRoot(String workingDirectory) {
  final file = _findNearestAncestor(
    where: (path) => _getWorkspaceRootPubspecYaml(cwd: Directory(path)),
    cwd: Directory(workingDirectory),
  );
  if (file == null || !file.existsSync()) return null;
  return Directory(path.dirname(file.path));
}

/// The workspace root `pubspec.yaml` file for this project.
File? _getWorkspaceRootPubspecYaml({required Directory cwd}) {
  try {
    final pubspecYamlFile = File(path.join(cwd.path, 'pubspec.yaml'));
    if (!pubspecYamlFile.existsSync()) return null;
    final pubspec = loadYaml(pubspecYamlFile.readAsStringSync());
    if (pubspec is! YamlMap) return null;
    final workspace = pubspec['workspace'] as List?;
    if (workspace?.isEmpty ?? true) return null;
    return pubspecYamlFile;
  } on Exception {
    return null;
  }
}

/// Finds nearest ancestor file
/// relative to the [cwd] that satisfies [where].
File? _findNearestAncestor({
  required File? Function(String path) where,
  required Directory cwd,
}) {
  Directory? prev;
  var dir = cwd;
  while (prev?.path != dir.path) {
    final file = where(dir.path);
    if (file?.existsSync() ?? false) return file;
    prev = dir;
    dir = dir.parent;
  }
  return null;
}
