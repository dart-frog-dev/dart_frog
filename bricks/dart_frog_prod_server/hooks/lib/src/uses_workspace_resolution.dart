import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

/// Determines whether the project in the provided [workingDirectory]
/// is configured to use `resolution: workspace`.
bool usesWorkspaceResolution(
  HookContext context, {
  required String workingDirectory,
  required void Function(int exitCode) exit,
}) {
  final pubspecFile = File(path.join(workingDirectory, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) return false;

  final Pubspec pubspec;
  try {
    pubspec = Pubspec.parse(pubspecFile.readAsStringSync());
  } on Exception catch (e) {
    context.logger.err('$e');
    exit(1);
    return false;
  }

  return pubspec.resolution == 'workspace';
}
