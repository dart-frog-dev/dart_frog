import 'dart:io';

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('getPathDependencies', () {
    test('returns nothing when there are no path dependencies', () {
      final directory = Directory.systemTemp.createTempSync();
      File(path.join(directory.path, 'pubspec.lock')).writeAsStringSync(
        '''
packages:
  test:
    dependency: transitive
    description:
      name: analyzer
      sha256: f85566ec7b3d25cbea60f7dd4f157c5025f2f19233ca4feeed33b616c78a26a3
      url: "https://pub.dev"
    source: hosted
    version: "6.1.0"
  mason:
    dependency: transitive
    description:
      name: analyzer
      sha256: f85566ec7b3d25cbea60f7dd4f157c5025f2f19233ca4feeed33b616c78a26a3
      url: "https://pub.dev"
    source: hosted
    version: "6.1.0"
''',
      );
      expect(getInternalPathDependencies(directory), completion(isEmpty));
      directory.delete(recursive: true).ignore();
    });

    test('returns correct path dependencies', () {
      final directory = Directory.systemTemp.createTempSync();
      File(path.join(directory.path, 'pubspec.lock')).writeAsStringSync(
        '''
packages:
  dart_frog:
    dependency: "direct main"
    description:
      path: "path/to/dart_frog"
      relative: true
    source: path
    version: "0.0.0"
  dart_frog_gen:
    dependency: "direct main"
    description:
      path: "path/to/dart_frog_gen"
      relative: true
    source: path
    version: "0.0.0"
''',
      );
      expect(
        getInternalPathDependencies(directory),
        completion(
          equals(['path/to/dart_frog', 'path/to/dart_frog_gen']),
        ),
      );
      directory.delete(recursive: true).ignore();
    });
  });
}
