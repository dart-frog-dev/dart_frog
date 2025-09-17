import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;

part 'package_graph.g.dart';

/// {@template package_graph}
/// A Dart object containing the deserialized contents of the package_graph.json
/// {@endtemplate}
@JsonSerializable()
class PackageGraph {
  /// {@macro package_graph}
  const PackageGraph({
    required this.roots,
    required this.packages,
    required this.configVersion,
  });

  /// Load a [PackageGraph] from the provided [project] root.
  factory PackageGraph.load(String project) {
    final file = File(path.join(project, '.dart_tool', 'package_graph.json'));
    if (!file.existsSync()) throw Exception('${file.path} not found');
    return PackageGraph.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  }

  /// Create a [PackageGraph] from a [Map].
  factory PackageGraph.fromJson(Map<String, dynamic> json) =>
      _$PackageGraphFromJson(json);

  /// The root nodes of the package graph.
  final List<String> roots;

  /// A list of packages for the given package graph.
  final List<PackageGraphPackage> packages;

  /// The config version of the package graph.
  final int configVersion;
}

/// {@template package_graph_package}
/// An individual package in a package graph.
/// {@endtemplate}
@JsonSerializable()
class PackageGraphPackage {
  /// {@macro package_graph_package}
  const PackageGraphPackage({
    required this.name,
    required this.version,
    required this.dependencies,
    required this.devDependencies,
  });

  /// Create a [PackageGraphPackage] from a [Map].
  factory PackageGraphPackage.fromJson(Map<String, dynamic> json) =>
      _$PackageGraphPackageFromJson(json);

  /// The name of the package.
  final String name;

  /// The version of the package.
  final String version;

  /// The list of package names that this package depends on in production.
  @JsonKey(defaultValue: <String>[])
  final List<String> dependencies;

  /// The list of package names that this package depends on in development.
  @JsonKey(defaultValue: <String>[])
  final List<String> devDependencies;
}
