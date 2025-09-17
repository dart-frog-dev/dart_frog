import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;

part 'package_graph.g.dart';

@JsonSerializable()
class PackageGraph {
  const PackageGraph({
    required this.roots,
    required this.packages,
    required this.configVersion,
  });

  factory PackageGraph.load(String project) {
    final file = File(path.join(project, '.dart_tool', 'package_graph.json'));
    if (!file.existsSync()) throw Exception('${file.path} not found');
    return PackageGraph.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  }

  factory PackageGraph.fromJson(Map<String, dynamic> json) =>
      _$PackageGraphFromJson(json);

  final List<String> roots;
  final List<Package> packages;
  final int configVersion;
}

@JsonSerializable()
class Package {
  const Package({
    required this.name,
    required this.version,
    required this.dependencies,
    required this.devDependencies,
  });

  factory Package.fromJson(Map<String, dynamic> json) =>
      _$PackageFromJson(json);

  final String name;
  final String version;

  @JsonKey(defaultValue: <String>[])
  final List<String> dependencies;

  @JsonKey(defaultValue: <String>[])
  final List<String> devDependencies;
}
