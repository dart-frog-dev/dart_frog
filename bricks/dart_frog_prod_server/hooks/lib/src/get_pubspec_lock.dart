import 'dart:io';

import 'package:dart_frog_prod_server_hooks/src/pubspec_lock/pubspec_lock.dart';
import 'package:path/path.dart' as path;

Future<PubspecLock> getPubspecLock(
  String workingDirectory, {
  path.Context? pathContext,
}) async {
  final pathResolver = pathContext ?? path.context;
  final pubspecLockFile = File(
    workingDirectory.isEmpty
        ? 'pubspec.lock'
        : pathResolver.join(workingDirectory, 'pubspec.lock'),
  );

  final content = await pubspecLockFile.readAsString();
  return PubspecLock.fromString(content);
}
