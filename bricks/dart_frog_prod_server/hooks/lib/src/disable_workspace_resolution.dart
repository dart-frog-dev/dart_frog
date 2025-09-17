import 'dart:io';
import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:mason/mason.dart';
import 'package:package_config/package_config.dart' as package_config;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Opts out of dart workspaces until we can generate per package lockfiles.
/// https://github.com/dart-lang/pub/issues/4594
VoidCallback disableWorkspaceResolution(
  HookContext context, {
  required package_config.PackageConfig packageConfig,
  required PackageGraph packageGraph,
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

  try {
    overridePathDependenciesInPubspecOverrides(
      projectDirectory: projectDirectory,
      packageConfig: packageConfig,
      packageGraph: packageGraph,
    );
  } on Exception catch (e) {
    restoreWorkspaceResolution();
    context.logger.err('$e');
    exit(1);
    return () {}; // no-op
  }

  return restoreWorkspaceResolution;
}

/// Add resolution:null to pubspec_overrides.yaml.
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

/// Add overrides for all path dependencies to `pubspec_overrides.yaml`
void overridePathDependenciesInPubspecOverrides({
  required String projectDirectory,
  required package_config.PackageConfig packageConfig,
  required PackageGraph packageGraph,
}) {
  final name = getPackageName(projectDirectory: projectDirectory);
  if (name == null) {
    throw Exception('Failed to parse "name" from pubspec.yaml');
  }

  final productionDeps = getProductionDependencies(
    packageName: name,
    packageGraph: packageGraph,
  );

  final pathDependencies = packageConfig.packages.where(
    (package) => package.relativeRoot && productionDeps.contains(package.name),
  );

  writePathDependencyOverrides(
    projectDirectory: projectDirectory,
    pathDependencies: pathDependencies,
  );
}

void writePathDependencyOverrides({
  required String projectDirectory,
  required Iterable<package_config.Package> pathDependencies,
}) {
  final pubspecOverridesFile = File(
    path.join(projectDirectory, 'pubspec_overrides.yaml'),
  );
  final contents = pubspecOverridesFile.readAsStringSync();
  final overrides = loadYaml(contents) as YamlMap;
  final editor = YamlEditor(contents);
  if (!overrides.containsKey('dependency_overrides')) {
    editor.update(['dependency_overrides'], {});
  }
  for (final package in pathDependencies) {
    editor.update(
      ['dependency_overrides', package.name],
      {'path': path.relative(package.root.path, from: projectDirectory)},
    );
  }
  pubspecOverridesFile.writeAsStringSync(editor.toString());
}

/// Extract the package name from the pubspec.yaml in [projectDirectory].
String? getPackageName({required String projectDirectory}) {
  final pubspecFile = File(path.join(projectDirectory, 'pubspec.yaml'));
  final pubspec = loadYaml(pubspecFile.readAsStringSync());
  if (pubspec is! YamlMap) return null;

  final name = pubspec['name'];
  if (name is! String) return null;

  return name;
}

/// Build a complete list of dependencies (direct and transitive).
Set<String> getProductionDependencies({
  required String packageName,
  required PackageGraph packageGraph,
}) {
  final dependencies = <String>{};
  final root = packageGraph.roots.firstWhere((root) => root == packageName);
  final rootPackage = packageGraph.packages.firstWhere((p) => p.name == root);
  final dependenciesToVisit = <String>[...rootPackage.dependencies];

  do {
    final discoveredDependencies = <String>[];
    for (final dependencyToVisit in dependenciesToVisit) {
      final package = packageGraph.packages.firstWhere(
        (p) => p.name == dependencyToVisit,
      );
      dependencies.add(package.name);
      for (final packageDependency in package.dependencies) {
        // Avoid infinite loops from dependency cycles (circular dependencies).
        if (dependencies.contains(packageDependency)) continue;
        discoveredDependencies.add(packageDependency);
      }
    }
    dependenciesToVisit
      ..clear()
      ..addAll(discoveredDependencies);
  } while (dependenciesToVisit.isNotEmpty);
  return dependencies;
}
