// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

part of 'package_graph.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageGraph _$PackageGraphFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PackageGraph',
      json,
      ($checkedConvert) {
        final val = PackageGraph(
          roots: $checkedConvert('roots',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          packages: $checkedConvert(
              'packages',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      PackageGraphPackage.fromJson(e as Map<String, dynamic>))
                  .toList()),
          configVersion:
              $checkedConvert('configVersion', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

PackageGraphPackage _$PackageGraphPackageFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PackageGraphPackage',
      json,
      ($checkedConvert) {
        final val = PackageGraphPackage(
          name: $checkedConvert('name', (v) => v as String),
          version: $checkedConvert('version', (v) => v as String),
          dependencies: $checkedConvert(
              'dependencies',
              (v) =>
                  (v as List<dynamic>?)?.map((e) => e as String).toList() ??
                  []),
          devDependencies: $checkedConvert(
              'devDependencies',
              (v) =>
                  (v as List<dynamic>?)?.map((e) => e as String).toList() ??
                  []),
        );
        return val;
      },
    );
