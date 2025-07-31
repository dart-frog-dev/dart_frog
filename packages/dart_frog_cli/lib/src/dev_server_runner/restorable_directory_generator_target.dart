import 'dart:collection';
import 'dart:io' as io;

import 'package:mason/mason.dart';

/// Signature for the [DirectoryGeneratorTarget.createFile] method.
typedef CreateFile =
    Future<GeneratedFile> Function(
      String path,
      List<int> contents, {
      Logger? logger,
      OverwriteRule? overwriteRule,
    });

/// Typedef for [RestorableDirectoryGeneratorTarget.new]
typedef RestorableDirectoryGeneratorTargetBuilder =
    RestorableDirectoryGeneratorTarget Function(
      io.Directory dir, {
      CreateFile? createFile,
      Logger? logger,
    });

/// {@template cached_file}
/// A cached file which consists of the file path and contents.
/// {@endtemplate}
class CachedFile {
  /// {@macro cached_file}
  const CachedFile({required this.path, required this.contents});

  /// The generated file path.
  final String path;

  /// The contents of the generated files.
  final List<int> contents;
}

/// {@template restorable_directory_generator_target}
/// A [DirectoryGeneratorTarget] that is capable of and restoring file
/// snapshots.
/// {@endtemplate}
class RestorableDirectoryGeneratorTarget extends DirectoryGeneratorTarget {
  /// {@macro restorable_directory_generator_target}
  RestorableDirectoryGeneratorTarget(
    super.dir, {
    CreateFile? createFile,
    Logger? logger,
  }) : _cachedSnapshots = Queue<CachedFile>(),
       _createFile = createFile,
       _logger = logger;

  final CreateFile? _createFile;
  final Logger? _logger;
  final Queue<CachedFile> _cachedSnapshots;

  CachedFile? get _cachedSnapshot {
    return _cachedSnapshots.isNotEmpty ? _cachedSnapshots.last : null;
  }

  CachedFile? _latestSnapshot;

  /// Removes the latest cached snapshot.
  void _removeLatestSnapshot() {
    _logger?.detail('[codegen] attempting to remove latest snapshot.');
    if (_cachedSnapshots.length > 1) {
      _cachedSnapshots.removeLast();
      _logger?.detail('[codegen] removed latest snapshot.');
    }
  }

  /// Remove the latest snapshot and restore the previously
  /// cached snapshot.
  Future<void> rollback() async {
    _logger?.detail('[codegen] rolling back...');
    _removeLatestSnapshot();
    await _restoreLatestSnapshot();
    _logger?.detail('[codegen] rollback complete.');
  }

  /// Restore the latest cached snapshot.
  Future<void> _restoreLatestSnapshot() async {
    final snapshot = _cachedSnapshot;
    if (snapshot == null) return;
    _logger?.detail('[codegen] restoring previous snapshot...');
    await createFile(snapshot.path, snapshot.contents);
    _logger?.detail('[codegen] restored previous snapshot.');
  }

  /// Cache the latest recorded snapshot.
  void cacheLatestSnapshot() {
    final snapshot = _latestSnapshot;
    if (snapshot == null) return;
    _cachedSnapshots.add(snapshot);
    _logger?.detail('[codegen] cached latest snapshot.');
    // Keep only the 2 most recent snapshots.
    if (_cachedSnapshots.length > 2) _cachedSnapshots.removeFirst();
  }

  @override
  Future<GeneratedFile> createFile(
    String path,
    List<int> contents, {
    Logger? logger,
    OverwriteRule? overwriteRule,
  }) {
    _latestSnapshot = CachedFile(path: path, contents: contents);
    return (_createFile ?? super.createFile)(
      path,
      contents,
      logger: logger,
      overwriteRule: overwriteRule,
    );
  }
}
