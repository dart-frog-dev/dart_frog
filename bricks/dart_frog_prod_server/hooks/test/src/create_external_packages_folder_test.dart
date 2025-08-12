import 'dart:io';

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../pubspecs.dart';

void main() {
  group('createExternalPackagesFolder', () {
    test('bundles external dependencies with external dependencies', () async {
      final projectDirectory = Directory.systemTemp.createTempSync();
      File(path.join(projectDirectory.path, 'pubspec.yaml'))
          .writeAsStringSync(fooPath);
      final copyCalls = <String>[];

      await createExternalPackagesFolder(
        projectDirectory: projectDirectory,
        buildDirectory: Directory(path.join(projectDirectory.path, 'build')),
        copyPath: (from, to) async => copyCalls.add('$from -> $to'),
      );

      final fooPackageDirectory = path.join(projectDirectory.path, '../../foo');
      final fooPackageDirectoryTarget = path.join(
        projectDirectory.path,
        'build',
        '.dart_frog_path_dependencies',
        'foo',
      );

      final foo2PackageDirectory =
          path.join(projectDirectory.path, '../../foo2');
      final foo2PackageDirectoryTarget = path.join(
        projectDirectory.path,
        'build',
        '.dart_frog_path_dependencies',
        'foo2',
      );

      expect(copyCalls, [
        '$fooPackageDirectory -> $fooPackageDirectoryTarget',
        '$foo2PackageDirectory -> $foo2PackageDirectoryTarget',
      ]);
    });

    test('does not bundle internal path dependencies', () async {
      final projectDirectory = Directory.systemTemp.createTempSync();
      File(
        path.join(projectDirectory.path, 'pubspec.yaml'),
      ).writeAsStringSync(fooPathWithInternalDependency);
      final copyCalls = <String>[];

      await createExternalPackagesFolder(
        projectDirectory: projectDirectory,
        buildDirectory: Directory(path.join(projectDirectory.path, 'build')),
        copyPath: (from, to) async => copyCalls.add('$from -> $to'),
      );

      final from = path.join(projectDirectory.path, '../../foo');
      final to = path.join(
        projectDirectory.path,
        'build',
        '.dart_frog_path_dependencies',
        'foo',
      );
      expect(copyCalls, ['$from -> $to']);
    });
  });
}
