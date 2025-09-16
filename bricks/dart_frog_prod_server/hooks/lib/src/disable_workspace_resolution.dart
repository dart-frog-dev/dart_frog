import 'dart:io';
import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:mason/mason.dart';
import 'package:package_config/package_config_types.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Opts out of dart workspaces until we can generate per package lockfiles.
/// https://github.com/dart-lang/pub/issues/4594
VoidCallback disableWorkspaceResolution(
  HookContext context, {
  required PackageConfig packageConfig,
  required String projectDirectory,
  required String workspaceRoot,
  required void Function(int exitCode) exit,
}) {
  final VoidCallback restoreWorkspaceResolution;
  try {
    restoreWorkspaceResolution = overrideResolutionInPubspecOverrides(
      projectDirectory,
    );
  } on Exception catch (e) {
    context.logger.err('$e');
    exit(1);
    return () {}; // no-op
  }

  // Get all package dependencies.
  final pubspecFile = File(path.join(projectDirectory, 'pubspec.yaml'));
  final pubspec = Pubspec.parse(pubspecFile.readAsStringSync());
  final allDependencies = [
    ...pubspec.dependencies.keys,
    ...pubspec.devDependencies.keys,
  ];

  // Find path dependencies based on the package_config.json.
  final pathDependencies = packageConfig.packages.where(
    (package) => package.relativeRoot && allDependencies.contains(package.name),
  );

  // Add dependency_overrides to the pubspec_overrides.yaml.
  final pubspecOverridesFile = File(
    path.join(projectDirectory, 'pubspec_overrides.yaml'),
  );
  final contents = pubspecOverridesFile.readAsStringSync();
  final editor = YamlEditor(contents)..update(['dependency_overrides'], {});
  for (final package in pathDependencies) {
    editor.update(
      ['dependency_overrides', package.name],
      {'path': path.relative(package.root.path, from: projectDirectory)},
    );
  }
  pubspecOverridesFile.writeAsStringSync(editor.toString());

  return restoreWorkspaceResolution;
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
