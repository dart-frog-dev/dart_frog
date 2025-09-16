import 'dart:io';
import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

/// Copies the pubspec.lock from the workspace root into the project directory
/// in order to ensure the production build uses the exact same versions of all
/// dependencies.
VoidCallback copyWorkspacePubspecLock(
  HookContext context, {
  required String projectDirectory,
  required String workspaceRoot,
  required void Function(int exitCode) exit,
}) {
  final pubspecLockFile = File(path.join(workspaceRoot, 'pubspec.lock'));
  if (!pubspecLockFile.existsSync()) return () {};

  try {
    pubspecLockFile.copySync(path.join(projectDirectory, 'pubspec.lock'));
    return () {
      File(path.join(projectDirectory, 'pubspec.lock')).delete().ignore();
    };
  } on Exception catch (error) {
    context.logger.err('$error');
    exit(1);
    return () {};
  }
}
