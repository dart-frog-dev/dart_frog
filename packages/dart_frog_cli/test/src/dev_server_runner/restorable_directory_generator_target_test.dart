import 'dart:convert';
import 'dart:io';

import 'package:dart_frog_cli/src/dev_server_runner/restorable_directory_generator_target.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FakeGeneratedFile extends Fake implements GeneratedFile {}

void main() {
  group('$CachedFile', () {
    test('can be instantiated', () {
      const path = './path';
      final contents = <int>[];
      final instance = CachedFile(path: path, contents: contents);
      expect(instance.path, equals(path));
      expect(instance.contents, equals(contents));
    });
  });

  group('$RestorableDirectoryGeneratorTarget', () {
    late RestorableDirectoryGeneratorTarget generatorTarget;
    late Directory directory;

    setUpAll(() {
      directory = Directory.systemTemp.createTempSync();
    });

    test('caches and restores snapshots when available', () async {
      const path = './path';
      final contents = utf8.encode('contents');
      final createdFiles = <CachedFile>[];

      generatorTarget = RestorableDirectoryGeneratorTarget(
        directory,
        createFile: (path, contents, {logger, overwriteRule}) async {
          createdFiles.add(CachedFile(path: path, contents: contents));
          return _FakeGeneratedFile();
        },
      );

      await generatorTarget.createFile(path, contents);

      expect(createdFiles.length, equals(1));

      createdFiles.clear();

      generatorTarget.cacheLatestSnapshot();

      const otherPath = './other/path';
      await generatorTarget.createFile(otherPath, contents);

      expect(createdFiles.length, equals(1));
      expect(createdFiles.first.path, equals(otherPath));
      expect(createdFiles.first.contents, equals(contents));

      createdFiles.clear();

      await generatorTarget.rollback();

      expect(createdFiles.length, equals(1));
      expect(createdFiles.first.path, equals(path));
      expect(createdFiles.first.contents, equals(contents));
    });

    test('caches only previous 2 snapshots', () async {
      const path = './path';
      final contents = utf8.encode('contents');
      final createdFiles = <CachedFile>[];

      generatorTarget = RestorableDirectoryGeneratorTarget(
        directory,
        createFile: (path, contents, {logger, overwriteRule}) async {
          createdFiles.add(CachedFile(path: path, contents: contents));
          return _FakeGeneratedFile();
        },
      );

      await generatorTarget.createFile(path, contents);
      generatorTarget.cacheLatestSnapshot();

      expect(createdFiles.length, equals(1));

      const otherPath = './other/path';
      await generatorTarget.createFile(otherPath, contents);
      generatorTarget.cacheLatestSnapshot();

      expect(createdFiles.length, equals(2));
      expect(createdFiles.first.path, equals(path));
      expect(createdFiles.first.contents, equals(contents));
      expect(createdFiles.last.path, equals(otherPath));
      expect(createdFiles.last.contents, equals(contents));

      const anotherPath = './another/path';
      await generatorTarget.createFile(anotherPath, contents);
      generatorTarget.cacheLatestSnapshot();

      expect(createdFiles.length, equals(3));
      expect(createdFiles.first.path, equals(path));
      expect(createdFiles.first.contents, equals(contents));
      expect(createdFiles[1].path, equals(otherPath));
      expect(createdFiles[1].contents, equals(contents));
      expect(createdFiles.last.path, equals(anotherPath));
      expect(createdFiles.last.contents, equals(contents));

      createdFiles.clear();

      for (var i = 0; i < 3; i++) {
        await generatorTarget.rollback();
      }

      expect(createdFiles.length, equals(3));
      expect(createdFiles.first.path, equals(otherPath));
      expect(createdFiles.first.contents, equals(contents));
      expect(createdFiles[1].path, equals(otherPath));
      expect(createdFiles[1].contents, equals(contents));
      expect(createdFiles.last.path, equals(otherPath));
      expect(createdFiles.last.contents, equals(contents));
    });

    test('restore does nothing when snapshot not available', () async {
      const path = './path';
      final contents = utf8.encode('contents');
      final createdFiles = <CachedFile>[];

      generatorTarget = RestorableDirectoryGeneratorTarget(
        directory,
        createFile: (path, contents, {logger, overwriteRule}) async {
          createdFiles.add(CachedFile(path: path, contents: contents));
          return _FakeGeneratedFile();
        },
      );

      await generatorTarget.createFile(path, contents);

      expect(createdFiles.length, equals(1));

      createdFiles.clear();

      const otherPath = './other/path';
      await generatorTarget.createFile(otherPath, contents);

      expect(createdFiles.length, equals(1));
      expect(createdFiles.first.path, equals(otherPath));
      expect(createdFiles.first.contents, equals(contents));

      createdFiles.clear();

      await generatorTarget.rollback();

      expect(createdFiles, isEmpty);
    });

    test('rollback does not remove snapshot '
        'when there is only one snapshot', () async {
      const path = './path';
      final contents = utf8.encode('contents');
      final createdFiles = <CachedFile>[];

      generatorTarget = RestorableDirectoryGeneratorTarget(
        directory,
        createFile: (path, contents, {logger, overwriteRule}) async {
          createdFiles.add(CachedFile(path: path, contents: contents));
          return _FakeGeneratedFile();
        },
      );

      await generatorTarget.createFile(path, contents);

      expect(createdFiles.length, equals(1));

      createdFiles.clear();

      generatorTarget.cacheLatestSnapshot();
      await generatorTarget.rollback();

      createdFiles.clear();

      const otherPath = './other/path';
      await generatorTarget.createFile(otherPath, contents);

      expect(createdFiles.length, equals(1));
      expect(createdFiles.first.path, equals(otherPath));
      expect(createdFiles.first.contents, equals(contents));

      createdFiles.clear();

      await generatorTarget.rollback();

      expect(createdFiles.length, equals(1));
      expect(createdFiles.first.path, equals(path));
      expect(createdFiles.first.contents, equals(contents));
    });

    test('rollback removes latest snapshot '
        'when there is more than one snapshot', () async {
      const path = './path';
      final contents = utf8.encode('contents');
      final createdFiles = <CachedFile>[];

      generatorTarget = RestorableDirectoryGeneratorTarget(
        directory,
        createFile: (path, contents, {logger, overwriteRule}) async {
          createdFiles.add(CachedFile(path: path, contents: contents));
          return _FakeGeneratedFile();
        },
      );

      await generatorTarget.createFile(path, contents);

      expect(createdFiles.length, equals(1));

      generatorTarget.cacheLatestSnapshot();

      const otherPath = './other/path';
      await generatorTarget.createFile(otherPath, contents);

      generatorTarget.cacheLatestSnapshot();

      expect(createdFiles.length, equals(2));
      expect(createdFiles.first.path, equals(path));
      expect(createdFiles.first.contents, equals(contents));
      expect(createdFiles.last.path, equals(otherPath));
      expect(createdFiles.last.contents, equals(contents));

      await generatorTarget.rollback();

      createdFiles.clear();

      await generatorTarget.rollback();

      expect(createdFiles.length, equals(1));
      expect(createdFiles.first.path, equals(path));
      expect(createdFiles.first.contents, equals(contents));
    });
  });
}
