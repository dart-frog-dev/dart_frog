import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

/// Opts out of dart workspaces until we can generate per package lockfiles.
/// https://github.com/dart-lang/pub/issues/4594
void disableWorkspaceResolution(
  HookContext context, {
  required String buildDirectory,
  required void Function(int exitCode) exit,
}) {
  try {
    File(
      path.join(buildDirectory, 'pubspec_overrides.yaml'),
    ).writeAsStringSync('resolution: null\n', mode: FileMode.append);
  } on Exception catch (e) {
    context.logger.err('$e');
    exit(1);
  }
}
