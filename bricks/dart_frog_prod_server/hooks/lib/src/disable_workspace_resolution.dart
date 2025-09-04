import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

/// Opts out of dart workspaces until we can generate per package lockfiles.
/// https://github.com/dart-lang/pub/issues/4594
void disableWorkspaceResolution(
  HookContext context, {
  required String projectDirectory,
  required void Function(int exitCode) exit,
}) {
  try {
    overrideResolutionInPubspecOverrides(projectDirectory);
  } on Exception catch (e) {
    context.logger.err('$e');
    exit(1);
  }
}

void overrideResolutionInPubspecOverrides(String projectDirectory) {
  final pubspecOverrides = File(
    path.join(projectDirectory, 'pubspec_overrides.yaml'),
  );

  if (pubspecOverrides.existsSync()) {
    return pubspecOverrides.writeAsStringSync(
      '\nresolution: null\n',
      mode: FileMode.append,
    );
  }

  pubspecOverrides
    ..createSync(recursive: true)
    ..writeAsStringSync('resolution: null');
}
