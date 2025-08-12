import 'dart:io';

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('getPathDependencies', () {
    test('returns nothing when there are no path dependencies', () {
      final directory = Directory.systemTemp.createTempSync();
      File(path.join(directory.path, 'pubspec.yaml')).writeAsStringSync(
        '''
name: _
dependencies:
  test: ^1.0.0
  mason: ^0.1.0
''',
      );
      expect(getInternalPathDependencies(directory), completion(isEmpty));
      directory.delete(recursive: true).ignore();
    });

    test('returns correct path dependencies', () {
      final directory = Directory.systemTemp.createTempSync();
      File(path.join(directory.path, 'pubspec.yaml')).writeAsStringSync(
        '''
name: _
dependencies:
  dart_frog:
    path: path/to/dart_frog
  dart_frog_gen:
    path: path/to/dart_frog_gen
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
