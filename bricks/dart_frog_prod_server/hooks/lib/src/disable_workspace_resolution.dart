import 'dart:io';
import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Opts out of dart workspaces until we can generate per package lockfiles.
/// https://github.com/dart-lang/pub/issues/4594
VoidCallback disableWorkspaceResolution(
  HookContext context, {
  required String projectDirectory,
  required void Function(int exitCode) exit,
}) {
  try {
    return overrideResolutionInPubspecOverrides(projectDirectory);
  } on Exception catch (e) {
    context.logger.err('$e');
    exit(1);
    return () {}; // no-op
  }
}

VoidCallback overrideResolutionInPubspecOverrides(String projectDirectory) {
  final pubspecOverridesFile = File(
    path.join(projectDirectory, 'pubspec_overrides.yaml'),
  );

  if (!pubspecOverridesFile.existsSync()) {
    pubspecOverridesFile.writeAsStringSync('resolution: null');
    return pubspecOverridesFile.deleteSync;
  }

  final contents = pubspecOverridesFile.readAsStringSync();
  final pubspecOverrides = loadYaml(contents) as YamlMap?;

  if (pubspecOverrides == null) {
    pubspecOverridesFile.writeAsStringSync('resolution: null');
    return () => pubspecOverridesFile.writeAsStringSync(contents);
  }

  if (pubspecOverrides['resolution'] == 'null') return () {}; // no-op

  final editor = YamlEditor(contents)..update(['resolution'], null);
  pubspecOverridesFile.writeAsStringSync(editor.toString());

  return () => pubspecOverridesFile.writeAsStringSync(contents);
}
