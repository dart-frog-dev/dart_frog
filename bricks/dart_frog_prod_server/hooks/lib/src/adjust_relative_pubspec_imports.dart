import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Fixes up the relative path imports in the build/pubspec.yaml
void adjustRelativePubspecImports(
  HookContext context, {
  required String buildDirectory,
  required void Function(int exitCode) exit,
}) {
  final pubspecFile = File(path.join(buildDirectory, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    context.logger.err('Unable to find ${pubspecFile.path}');
    exit(1);
  }

  final String contents;
  final Pubspec pubspec;
  try {
    contents = pubspecFile.readAsStringSync();
    pubspec = Pubspec.parse(contents);
  } on Exception catch (e) {
    context.logger.err('$e');
    return exit(1);
  }

  final yamlEditor = YamlEditor(contents);
  for (final dependency in pubspec.dependencies.entries) {
    final dep = dependency.value;
    if (dep is! PathDependency) continue;
    yamlEditor.update(
      ['dependencies', dependency.key, 'path'],
      path.relative(dep.path, from: buildDirectory),
    );
  }

  pubspecFile.writeAsStringSync(yamlEditor.toString());
}
