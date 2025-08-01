import 'package:path/path.dart' as p;

/// A parsed route file.
class RouteFile {
  RouteFile._(this.path, this.parameters);

  /// The route path relative to the "routes" directory.
  final String path;

  /// The parameter names in the route path.
  final List<String> parameters;
}

/// Decode a route path into a [RouteFile].
RouteFile parseRoute(String path) {
  final routePath = _findEnclosingRouteDirectory(path);
  if (routePath == null) {
    throw ArgumentError.value(
      path,
      'path',
      'The path must be within a "routes" directory.',
    );
  }

  final relativePath = p.relative(path, from: routePath);
  final split = p.split(relativePath);
  final parameters = split
      .map(p.basenameWithoutExtension)
      .where((element) => element.startsWith('[') && element.endsWith(']'))
      .map((e) => e.substring(1, e.length - 1))
      .toList();

  return RouteFile._(relativePath, parameters);
}

/// Find the enclosing "routes" directory of a route path.
String? _findEnclosingRouteDirectory(String path) {
  final split = p.split(path);
  final routeIndex = split.lastIndexOf('routes');
  if (routeIndex == -1) return null;

  return p.joinAll(split.sublist(0, routeIndex));
}
