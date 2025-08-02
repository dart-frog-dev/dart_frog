import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:yaml/yaml.dart';

/// {@template pubspec_lock_parse_exception}
/// Thrown when a [PubspecLock] fails to parse.
/// {@endtemplate}
class PubspecLockParseException implements Exception {
  /// {@macro pubspec_lock_parse_exception}
  const PubspecLockParseException();
}

/// A representation of a pubspec.lock file.
class PubspecLock {
  const PubspecLock._({
    required this.packages,
  });

  /// Parses a [PubspecLock] from a string.
  ///
  /// If no packages are found, an empty [PubspecLock] is returned. Those
  /// packages entries that cannot be parsed are ignored.
  ///
  /// It throws a [PubspecLockParseException] if the string cannot be parsed
  /// as a [YamlMap].
  factory PubspecLock.fromString(String content) {
    late final YamlMap yaml;
    try {
      yaml = loadYaml(content) as YamlMap;
    } on Exception catch (_) {
      throw const PubspecLockParseException();
    }

    if (!yaml.containsKey('packages')) {
      return PubspecLock.empty;
    }

    final packages = yaml['packages'] as YamlMap;

    final parsedPackages = <PubspecLockPackage>[];
    for (final entry in packages.entries) {
      try {
        final package = PubspecLockPackage.fromYamlMap(
          name: entry.key as String,
          data: entry.value as YamlMap,
        );
        parsedPackages.add(package);
      } on Exception catch (_) {
        // Ignore those packages that for some reason cannot be parsed.
      }
    }

    return PubspecLock._(
      packages: UnmodifiableListView(parsedPackages),
    );
  }

  /// An empty [PubspecLock].
  static PubspecLock empty = PubspecLock._(
    packages: UnmodifiableListView([]),
  );

  /// All the dependencies in the pubspec.lock file.
  final UnmodifiableListView<PubspecLockPackage> packages;
}

/// {@template pubspec_lock_dependency}
/// A representation of a dependency in a pubspec.lock file.
/// {@endtemplate}
class PubspecLockPackage extends Equatable {
  /// {@macro pubspec_lock_dependency}
  const PubspecLockPackage({
    required this.name,
    required this.type,
    this.pathDescription,
  });

  /// Parses a [PubspecLockPackage] from a [YamlMap].
  factory PubspecLockPackage.fromYamlMap({
    required String name,
    required YamlMap data,
  }) {
    final dependency = data['dependency'] as String;
    final dependencyType = PubspecLockPackageDependencyType.parse(dependency);

    final description = data['description'] as YamlMap?;
    final pathDescription = description != null
        ? PubspecPackagePathDescription.tryParse(description)
        : null;

    return PubspecLockPackage(
      name: name,
      type: dependencyType,
      pathDescription: pathDescription,
    );
  }

  /// The name of the dependency.
  final String name;

  /// {@macro pubspec_lock_dependency_type}
  final PubspecLockPackageDependencyType type;

  /// {@macro pubspec_package_path_description}
  final PubspecPackagePathDescription? pathDescription;

  @override
  List<Object?> get props => [name, type, pathDescription];
}

/// {@template pubspec_lock_dependency_type}
/// The type of a [PubspecLockPackage].
/// {@endtemplate}
enum PubspecLockPackageDependencyType {
  /// Another package that your package needs to work.
  ///
  /// See also:
  ///
  /// * [Dart's dependency documentation](https://dart.dev/tools/pub/dependencies)
  directMain._('direct main'),

  /// Another package that your package needs during development.
  ///
  /// See also:
  ///
  /// * [Dart's developer dependency documentation](https://dart.dev/tools/pub/dependencies#dev-dependencies)
  directDev._('direct dev'),

  /// A dependency that your package indirectly uses because one of its
  /// dependencies requires it.
  ///
  /// See also:
  ///
  /// * [Dart's transitive dependency documentation](https://dart.dev/tools/pub/glossary#transitive-)
  transitive._('transitive'),

  ///  A dependency that your package overrides that is not already a
  /// `direct main` or `direct dev` dependency.
  ///
  /// See also:
  ///
  /// * [Dart's dependency override documentation](https://dart.dev/tools/pub/dependencies#dependency-overrides)
  directOverridden._('direct overridden');

  const PubspecLockPackageDependencyType._(this.value);

  /// Parses a [PubspecLockPackageDependencyType] from a string.
  ///
  /// Throws an [ArgumentError] if the string is not a valid dependency type.
  factory PubspecLockPackageDependencyType.parse(String value) {
    if (_valueMap.containsKey(value)) {
      return _valueMap[value]!;
    }

    throw ArgumentError.value(
      value,
      'value',
      'Invalid PubspecLockPackageDependencyType value.',
    );
  }

  static Map<String, PubspecLockPackageDependencyType> _valueMap = {
    for (final type in PubspecLockPackageDependencyType.values)
      type.value: type,
  };

  /// The string representation of the [PubspecLockPackageDependencyType]
  /// as it appears in a pubspec.lock file.
  final String value;
}

/// {@template pubspec_package_path_description}
/// The description of a path dependency in a pubspec.lock file.
///
/// For example, in:
/// ```yaml
/// my_package:
///   dependency: "direct main"
///   description:
///     path: "packages/my_package"
///     relative: true
///   source: path
///   version: "1.0.0+1"
/// ```
///
/// The description is:
/// ```yaml
/// path: "packages/my_package"
/// relative: true
/// ```
///
/// See also:
///
/// * [PubspecPackagePathDescription.tryParse], which attempts to parses a
/// [YamlMap] into a [PubspecPackagePathDescription].
/// {@endtemplate}
class PubspecPackagePathDescription extends Equatable {
  const PubspecPackagePathDescription({
    required this.path,
    required this.relative,
  });

  /// Attempts to parse a [YamlMap] into a [PubspecPackagePathDescription].
  ///
  /// Returns `null` if the [YamlMap] does not contain the required data
  /// to create a [PubspecPackagePathDescription].
  static PubspecPackagePathDescription? tryParse(YamlMap data) {
    if ((!data.containsKey('path') || data['path'] is! String) ||
        (!data.containsKey('relative') || data['relative'] is! bool)) {
      return null;
    }

    final path = data['path'] as String;
    final relative = data['relative'] as bool;

    return PubspecPackagePathDescription(
      path: path,
      relative: relative,
    );
  }

  final String path;
  final bool relative;

  @override
  List<Object?> get props => [path, relative];
}
