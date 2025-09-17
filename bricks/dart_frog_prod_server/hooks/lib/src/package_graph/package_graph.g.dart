// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'package_graph.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageGraph _$PackageGraphFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackageGraph', json, ($checkedConvert) {
      final val = PackageGraph(
        roots: $checkedConvert(
          'roots',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        packages: $checkedConvert(
          'packages',
          (v) => (v as List<dynamic>)
              .map((e) => Package.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        configVersion: $checkedConvert(
          'configVersion',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Package _$PackageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Package', json, ($checkedConvert) {
      final val = Package(
        name: $checkedConvert('name', (v) => v as String),
        version: $checkedConvert('version', (v) => v as String),
        dependencies: $checkedConvert(
          'dependencies',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        ),
        devDependencies: $checkedConvert(
          'devDependencies',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        ),
      );
      return val;
    });
