import 'dart:io';
import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:mason/mason.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Opts out of dart workspaces until we can generate per package lockfiles.
/// https://github.com/dart-lang/pub/issues/4594
VoidCallback disableWorkspaceResolution(
  HookContext context, {
  required PackageConfig packageConfig,
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
    overrideDependenciesInPubspecOverrides(
      projectDirectory: projectDirectory,
      packageConfig: packageConfig,
      packageGraph: packageGraph,
      workspaceRoot: workspaceRoot,
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

/// Add overrides for all neccessary dependencies to `pubspec_overrides.yaml`
void overrideDependenciesInPubspecOverrides({
  required String projectDirectory,
  required PackageConfig packageConfig,
  required PackageGraph packageGraph,
  required String workspaceRoot,
}) {
  final name = getPackageName(projectDirectory: projectDirectory);
  if (name == null) {
    throw Exception('Failed to parse "name" from pubspec.yaml');
  }

  final productionDeps = getProductionDependencies(
    packageName: name,
    packageGraph: packageGraph,
  );

  final pathDependencies = packageConfig.packages
      .where((p) => p.relativeRoot && productionDeps.contains(p.name))
      .map((p) => PathDependency(name: p.name, path: p.root.path));

  final workspaceRootOverrides = getWorkspaceRootDependencyOverrides(
    workspaceRoot: workspaceRoot,
  );
  final productionOverrides = workspaceRootOverrides.entries.where(
    (e) => productionDeps.contains(e.key),
  );

  final overrides = <String, dynamic>{
    for (final pathDependency in pathDependencies)
      pathDependency.name: {
        'path': path.relative(pathDependency.path, from: projectDirectory),
      },
    for (final override in productionOverrides)
      '${override.key}': override.value,
  };

  writeDependencyOverrides(
    projectDirectory: projectDirectory,
    overrides: overrides,
  );
}

void writeDependencyOverrides({
  required String projectDirectory,
  required Map<String, dynamic> overrides,
}) {
  final pubspecOverridesFile = File(
    path.join(projectDirectory, 'pubspec_overrides.yaml'),
  );
  final contents = pubspecOverridesFile.readAsStringSync();
  final pubspecOverrides = loadYaml(contents) as YamlMap;
  final editor = YamlEditor(contents);
  if (!pubspecOverrides.containsKey('dependency_overrides')) {
    editor.update(['dependency_overrides'], {});
  }
  for (final override in overrides.entries) {
    editor.update(
      ['dependency_overrides', override.key],
      override.value,
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

YamlMap getWorkspaceRootDependencyOverrides({required String workspaceRoot}) {
  final pubspecOverridesFile = File(
    path.join(workspaceRoot, 'pubspec_overrides.yaml'),
  );
  if (!pubspecOverridesFile.existsSync()) return YamlMap();

  final pubspecOverrides = loadYaml(pubspecOverridesFile.readAsStringSync());
  if (pubspecOverrides is! YamlMap) return YamlMap();

  final overrides = pubspecOverrides['dependency_overrides'];
  if (overrides is! YamlMap) return YamlMap();

  return overrides;
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
