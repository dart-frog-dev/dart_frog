import 'dart:io';

import 'package:dart_frog_gen/src/path_to_route.dart';
import 'package:path/path.dart' as path;

/// Build a [RouteConfiguration] based on the provided root project [directory].
RouteConfiguration buildRouteConfiguration(Directory directory) {
  final routesDirectory = Directory(path.join(directory.path, 'routes'));

  if (!routesDirectory.existsSync()) {
    throw Exception('Could not find directory ${routesDirectory.path}');
  }

  final globalMiddlewareFile = File(
    path.join(routesDirectory.path, '_middleware.dart'),
  );
  final globalMiddleware = globalMiddlewareFile.existsSync()
      ? MiddlewareFile(
          name: 'middleware',
          path: path
              .join('..', path.relative(globalMiddlewareFile.path))
              .replaceAll(r'\', '/'),
        )
      : null;

  final endpoints = <String, List<RouteFile>>{};
  final middleware = <MiddlewareFile>[
    if (globalMiddleware != null) globalMiddleware,
  ];
  final routes = <RouteFile>[];
  final rogueRoutes = <RouteFile>[];
  final directories = _getRouteDirectories(
    directory: routesDirectory,
    routesDirectory: routesDirectory,
    onRoute: routes.add,
    onMiddleware: middleware.add,
    onEndpoint: (endpoint, file) {
      if (!endpoints.containsKey(endpoint)) {
        endpoints[endpoint] = [file];
      } else {
        endpoints[endpoint]!.add(file);
      }
    },
    onRogueRoute: rogueRoutes.add,
  );
  final publicDirectory = Directory(path.join(directory.path, 'public'));
  final mainDartFile = File(path.join(directory.path, 'main.dart'));

  final customInitRegex = RegExp(
    r'^Future(?:Or)?<void>\s*init\(InternetAddress .*?,\s*int .*?\)\s*(?:async)?\s*{',
    multiLine: true,
  );

  final mainDartFileExists = mainDartFile.existsSync();
  final hasCustomInit = mainDartFileExists &&
      customInitRegex.hasMatch(mainDartFile.readAsStringSync());

  return RouteConfiguration(
    globalMiddleware: globalMiddleware,
    middleware: middleware,
    directories: directories,
    routes: routes,
    rogueRoutes: rogueRoutes,
    endpoints: endpoints,
    serveStaticFiles: publicDirectory.existsSync(),
    invokeCustomEntrypoint: mainDartFileExists,
    invokeCustomInit: hasCustomInit,
  );
}

List<RouteDirectory> _getRouteDirectories({
  required Directory directory,
  required Directory routesDirectory,
  required void Function(RouteFile route) onRoute,
  required void Function(MiddlewareFile route) onMiddleware,
  required void Function(String endpoint, RouteFile file) onEndpoint,
  required void Function(RouteFile route) onRogueRoute,
  List<MiddlewareFile> middleware = const [],
}) {
  final directories = <RouteDirectory>[];
  final entities = directory.listSync().sorted();
  final directorySegment =
      directory.path.split('routes').last.replaceAll(r'\', '/');
  final directoryPath = directorySegment.startsWith('/')
      ? directorySegment
      : '/$directorySegment';
  // Only add nested middleware -- global middleware is added separately.
  MiddlewareFile? localMiddleware;
  if (directory.path != path.join(Directory.current.path, 'routes')) {
    final middlewareFile = File(path.join(directory.path, '_middleware.dart'));
    if (middlewareFile.existsSync()) {
      final middlewarePath = path
          .relative(middlewareFile.path, from: routesDirectory.path)
          .replaceAll(r'\', '/');
      localMiddleware = MiddlewareFile(
        name: middlewarePath.toAlias(),
        path: path.join('..', 'routes', middlewarePath).replaceAll(r'\', '/'),
      );
      onMiddleware(localMiddleware);
    }
  }

  final updatedMiddleware = [
    ...middleware,
    if (localMiddleware != null) localMiddleware,
  ];

  final files = _getRouteFiles(
    directory: directory,
    routesDirectory: routesDirectory,
    onRoute: onRoute,
    onRogueRoute: onRogueRoute,
  );

  if (files.isNotEmpty) {
    final baseRoute = directoryPath.toRoute();
    for (final file in files) {
      var endpoint = (baseRoute + file.route.toRoute()).replaceAll('//', '/');
      if (endpoint.endsWith('/')) {
        endpoint = endpoint.substring(0, endpoint.length - 1);
      }
      if (endpoint.isEmpty) endpoint = '/';
      onEndpoint(endpoint, file);
    }

    if (directoryPath.isWildcard()) {
      throw ArgumentError('Only files can be named with a wildcard alias.');
    }

    directories.add(
      RouteDirectory(
        name: directoryPath.toAlias(),
        route: baseRoute,
        middleware: updatedMiddleware,
        files: files,
        params: directoryPath.toParams(),
      ),
    );
  }

  entities.whereType<Directory>().forEach((directory) {
    directories.addAll(
      _getRouteDirectories(
        directory: directory,
        routesDirectory: routesDirectory,
        onRoute: onRoute,
        onMiddleware: onMiddleware,
        onEndpoint: onEndpoint,
        onRogueRoute: onRogueRoute,
        middleware: updatedMiddleware,
      ),
    );
  });

  return directories;
}

List<RouteFile> _getRouteFiles({
  required Directory directory,
  required Directory routesDirectory,
  required void Function(RouteFile route) onRoute,
  required void Function(RouteFile route) onRogueRoute,
  String prefix = '',
}) {
  final files = <RouteFile>[];
  final directorySegment =
      directory.path.split('routes').last.replaceAll(r'\', '/');
  final directoryPath = directorySegment.startsWith('/')
      ? directorySegment
      : '/$directorySegment';
  final entities = directory.listSync().sorted();
  final subDirectories = entities
      .whereType<Directory>()
      .map((directory) => path.basename(directory.path))
      .toSet();

  int segmentCount(String route) =>
      route.split('/').where((p) => p.isNotEmpty).length;

  bool isDynamicSegment(String part) =>
      part.startsWith('<') && part.endsWith('>');

  int staticSegmentCount(String route) {
    final parts = route.split('/').where((p) => p.isNotEmpty);
    return parts.where((p) => !isDynamicSegment(p)).length;
  }

  entities.where((e) => e.isRoute).cast<File>().forEach((entity) {
    final filePath = path
        .relative(entity.path, from: routesDirectory.path)
        .replaceAll(r'\', '/');

    String getFileRoute() {
      final routePath = pathToRoute(path.join('..', 'routes', filePath));
      final index = routePath.indexOf(directoryPath);
      final fileRoutePath = index == -1
          ? routePath
          : routePath.substring(index + directoryPath.length);

      var fileRoute = fileRoutePath.isEmpty ? '/' : fileRoutePath;
      fileRoute = prefix + fileRoute;

      if (!fileRoute.startsWith('/')) fileRoute = '/$fileRoute';

      return fileRoute;
    }

    final fileRoute = getFileRoute();
    final relativeFilePath = path.join('..', 'routes', filePath);

    final isWildcard = filePath.isWildcard();

    final route = RouteFile(
      name: filePath.toAlias(),
      path: relativeFilePath.replaceAll(r'\', '/'),
      route: fileRoute.toRoute(),
      params: fileRoute.toParams(),
      wildcard: isWildcard,
    );
    onRoute(route);
    files.add(route);

    final fileBasename = path.basenameWithoutExtension(filePath);
    final conflictingIndexFile = File(
      path.join(directory.path, fileBasename, 'index.dart'),
    );
    final isRogueRoute = subDirectories.contains(fileBasename) &&
        !conflictingIndexFile.existsSync();

    if (isRogueRoute) onRogueRoute(route);
  });

  files.sort((a, b) {
    // Non-wildcard routes first
    if (a.wildcard != b.wildcard) {
      return a.wildcard ? 1 : -1;
    }

    // Routes with more static path segments first
    final aStaticSegments = staticSegmentCount(a.route);
    final bStaticSegments = staticSegmentCount(b.route);
    if (aStaticSegments != bStaticSegments) {
      return bStaticSegments.compareTo(aStaticSegments);
    }

    // Routes with more total path segments first
    final aTotalSegments = segmentCount(a.route);
    final bTotalSegments = segmentCount(b.route);
    if (aTotalSegments != bTotalSegments) {
      return bTotalSegments.compareTo(aTotalSegments);
    }

    // Deterministic fallback
    return a.route.compareTo(b.route);
  });

  return files;
}

/// Extension on [String] with helper methods regarding
/// Dart Frog routes.
extension RouteStringX on String {
  /// Parses the stirng into a route alias.
  String toAlias() {
    final alias = path
        .withoutExtension(this)
        .replaceAll('[', r'$')
        .replaceAll(']', '')
        .replaceAll('/', '_')
        .replaceAll('...', 'wildcard_');
    if (alias == '') return 'index';
    return alias;
  }

  /// Returns if this value matches a wildcard route.
  bool isWildcard() {
    final value = endsWith('.dart')
        ? path.basenameWithoutExtension(this)
        : path.basename(this);

    return RegExp(r'\[\.\.\.(.*?)\]').hasMatch(value);
  }

  /// Parses the string into a route path.
  String toRoute() {
    if (isWildcard()) return '/';
    return replaceAll('[', '<').replaceAll(']', '>').replaceAll(r'\', '/');
  }

  /// Parses the string into a list of route parameters.
  List<String> toParams() {
    final regexp = RegExp(r'\[(.*?)\]');
    final matches = regexp.allMatches(this);
    return matches.map((m) {
      final match = m[0]!;
      return match.replaceAll(RegExp(r'\[|\]'), '').replaceFirst('...', '');
    }).toList();
  }
}

extension on List<FileSystemEntity> {
  List<FileSystemEntity> sorted() {
    return this..sort((a, b) => b.path.compareTo(a.path));
  }
}

extension on FileSystemEntity {
  bool get isRoute {
    return this is File &&
        path.basename(this.path).endsWith('.dart') &&
        path.basename(this.path) != '_middleware.dart';
  }
}

/// {@template route_configuration}
/// An object containing all route configuration metadata
/// required to generate a dart frog server.
/// {@endtemplate}
class RouteConfiguration {
  /// {@macro route_configuration}
  const RouteConfiguration({
    required this.middleware,
    required this.directories,
    required this.routes,
    required this.endpoints,
    required this.rogueRoutes,
    this.globalMiddleware,
    this.serveStaticFiles = false,
    this.invokeCustomEntrypoint = false,
    this.invokeCustomInit = false,
  });

  /// Whether to invoke a custom entrypoint script (`main.dart`).
  final bool invokeCustomEntrypoint;

  /// Whether to invoke a custom init method (`init` in `main.dart`).
  final bool invokeCustomInit;

  /// Whether to serve static files. Defaults to false.
  final bool serveStaticFiles;

  /// Optional global middleware.
  final MiddlewareFile? globalMiddleware;

  /// List of all nested middleware.
  /// Top-level middleware is excluded (see [globalMiddleware]).
  final List<MiddlewareFile> middleware;

  /// List of all route directories.
  /// Sorted from leaf nodes to root.
  final List<RouteDirectory> directories;

  /// List of all route files.
  final List<RouteFile> routes;

  /// A map of all endpoint paths to resolved route files.
  final Map<String, List<RouteFile>> endpoints;

  /// List of all rogue routes.
  ///
  /// A route is considered rogue when it is defined outside
  /// of an existing subdirectory with the same name.
  ///
  /// For example:
  ///
  /// ```markdown
  /// ├── routes
  /// │   ├── foo
  /// │   │   └── example.dart
  /// │   ├── foo.dart
  /// ```
  ///
  /// In the above scenario, `foo.dart` is rogue because it is defined
  /// outside of the existing `foo` directory.
  ///
  /// Instead, `foo.dart` should be renamed to `index.dart` and placed within
  /// the `foo` directory like:
  ///
  /// ```markdown
  /// ├── routes
  /// │   ├── foo
  /// │   │   ├── example.dart
  /// │   │   └── index.dart
  /// ```
  final List<RouteFile> rogueRoutes;

  /// Transform into json
  Map<String, dynamic> toJson() {
    return {
      'invokeCustomEntrypoint': invokeCustomEntrypoint,
      'invokeCustomInit': invokeCustomInit,
      'serveStaticFiles': serveStaticFiles,
      'globalMiddleware': globalMiddleware?.toJson(),
      'middleware': middleware.map((e) => e.toJson()).toList(),
      'directories': directories.map((e) => e.toJson()).toList(),
      'routes': routes.map((e) => e.toJson()).toList(),
      'endpoints': endpoints.map(
        (key, value) => MapEntry(
          key,
          value.map((e) => e.toJson()).toList(),
        ),
      ),
      'rogueRoutes': rogueRoutes.map((e) => e.toJson()).toList(),
    };
  }
}

/// {@template route_directory}
/// A class containing metadata regarding a route directory.
/// {@endtemplate}
class RouteDirectory {
  /// {@macro route_directory}
  const RouteDirectory({
    required this.name,
    required this.route,
    required this.middleware,
    required this.files,
    required this.params,
  });

  /// The alias for the current directory.
  final String name;

  /// The route which will be used to mount routers.
  final String route;

  /// The dynamic route params associated with the directory.
  final List<String> params;

  /// List of middleware for the provided router.
  final List<MiddlewareFile> middleware;

  /// A list of nested route files within the directory.
  final List<RouteFile> files;

  /// Create a copy of the current instance and override zero or more values.
  RouteDirectory copyWith({
    String? name,
    String? route,
    List<MiddlewareFile>? middleware,
    List<RouteFile>? files,
    List<String>? params,
  }) {
    return RouteDirectory(
      name: name ?? this.name,
      route: route ?? this.route,
      middleware: middleware ?? this.middleware,
      files: files ?? this.files,
      params: params ?? this.params,
    );
  }

  /// Convert the current instance to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'route': route,
      'middleware': middleware.map((m) => m.toJson()).toList(),
      'files': files.map((f) => f.toJson()).toList(),
      'directory_params': params,
    };
  }
}

/// {@template route_file}
/// A class containing metadata regarding a route file.
/// {@endtemplate}
class RouteFile {
  /// {@macro route_file}
  const RouteFile({
    required this.name,
    required this.path,
    required this.route,
    required this.params,
    required this.wildcard,
  });

  /// The alias for the current file.
  final String name;

  /// The import path for the current instance.
  final String path;

  /// The route used by router instances.
  final String route;

  /// The dynamic route params associated with the file.
  final List<String> params;

  /// Whether the route is a wildcard route.
  final bool wildcard;

  /// Create a copy of the current instance and override zero or more values.
  RouteFile copyWith({
    String? name,
    String? path,
    String? route,
    List<String>? params,
    bool? wildcard,
  }) {
    return RouteFile(
      name: name ?? this.name,
      path: path ?? this.path,
      route: route ?? this.route,
      params: params ?? this.params,
      wildcard: wildcard ?? this.wildcard,
    );
  }

  /// Convert the current instance to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'path': path,
      'route': route,
      'file_params': params,
      'wildcard': wildcard,
    };
  }
}

/// {@template middleware_file}
/// A class containing metadata regarding a route directory.
/// {@endtemplate}
class MiddlewareFile {
  /// {@macro middleware_file}
  const MiddlewareFile({
    required this.name,
    required this.path,
  });

  /// The alias for the current directory.
  final String name;

  /// The import path for the current instance.
  final String path;

  /// Create a copy of the current instance and override zero or more values.
  MiddlewareFile copyWith({String? name, String? path}) {
    return MiddlewareFile(
      name: name ?? this.name,
      path: path ?? this.path,
    );
  }

  /// Convert the current instance to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'path': path,
    };
  }
}
