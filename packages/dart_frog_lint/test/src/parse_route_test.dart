import 'package:dart_frog_lint/src/parse_route.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('parseRoute', () {
    test('throws if path is not within a "routes" directory', () {
      final path = p.join('path', 'to', 'file.dart');
      expect(() => parseRoute(path), throwsArgumentError);
    });

    test('parses a route path', () {
      final path = p.join('routes', 'path', 'to', 'file.dart');
      final route = parseRoute(path);

      expect(route.path, 'routes/path/to/file.dart');
      expect(route.parameters, isEmpty);
    });

    test('parses a route with parameters', () {
      final path = p.join('routes', '[path]', 'to', '[file].dart');
      final route = parseRoute(path);

      expect(route.path, 'routes/[path]/to/[file].dart');
      expect(route.parameters, ['path', 'file']);
    });

    test('[] must be placed around the entire parameter name', () {
      final path = p.join('routes', 'p[ath]', 'to', '[fil]e.dart');
      final route = parseRoute(path);

      expect(route.path, 'routes/p[ath]/to/[fil]e.dart');
      expect(route.parameters, isEmpty);
    });
  });
}
