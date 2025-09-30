import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Determines whether the project in the provided [workingDirectory]
/// is configured to use `resolution: workspace`.
bool usesWorkspaceResolution(
  HookContext context, {
  required String workingDirectory,
  required void Function(int exitCode) exit,
}) {
  final pubspecFile = File(path.join(workingDirectory, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) return false;

  final YamlMap pubspec;
  try {
    final yaml = loadYaml(pubspecFile.readAsStringSync());
    if (yaml is! YamlMap) {
      throw Exception('Unable to parse ${pubspecFile.path}');
    }
    pubspec = yaml;
  } on Exception catch (e) {
    context.logger.err('$e');
    exit(1);
    return false;
  }

  return pubspec['resolution'] == 'workspace';
}
