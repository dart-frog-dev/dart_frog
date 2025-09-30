import 'dart:io';

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../pubspec_locks.dart';

void main() {
  group('createExternalPackagesFolder', () {
    test('bundles external dependencies with external dependencies', () async {
      final projectDirectory = Directory.systemTemp.createTempSync();
      File(path.join(projectDirectory.path, 'pubspec.lock'))
          .writeAsStringSync(fooPath);
      final copyCalls = <String>[];

      await createExternalPackagesFolder(
        projectDirectory: projectDirectory,
        buildDirectory: Directory(path.join(projectDirectory.path, 'build')),
        copyPath: (from, to) async {
          copyCalls.add('$from -> $to');
          File(
            path.join(to, 'pubspec_overrides.yaml'),
          ).createSync(recursive: true);
        },
      );

      final fooPackageDirectory = path.join(projectDirectory.path, '../../foo');
      final fooPackageDirectoryTarget = path.join(
        projectDirectory.path,
        'build',
        '.dart_frog_path_dependencies',
        'foo',
      );

      final secondFooPackageDirectory = path.join(
        projectDirectory.path,
        '../../foo2',
      );
      final secondFooPackageDirectoryTarget = path.join(
        projectDirectory.path,
        'build',
        '.dart_frog_path_dependencies',
        'second_foo',
      );
      expect(copyCalls, [
        '$fooPackageDirectory -> $fooPackageDirectoryTarget',
        '$secondFooPackageDirectory -> $secondFooPackageDirectoryTarget',
      ]);
    });

    test("doesn't bundle internal path dependencies", () async {
      final projectDirectory = Directory.systemTemp.createTempSync();
      File(path.join(projectDirectory.path, 'pubspec.lock'))
          .writeAsStringSync(fooPathWithInternalDependency);
      final copyCalls = <String>[];

      await createExternalPackagesFolder(
        projectDirectory: projectDirectory,
        buildDirectory: Directory(path.join(projectDirectory.path, 'build')),
        copyPath: (from, to) async {
          copyCalls.add('$from -> $to');
          File(
            path.join(to, 'pubspec_overrides.yaml'),
          ).createSync(recursive: true);
        },
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
