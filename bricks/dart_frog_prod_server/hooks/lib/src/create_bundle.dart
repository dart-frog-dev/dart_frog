import 'dart:io' as io;

import 'package:io/io.dart' show copyPath;
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

Future<void> createBundle({
  required HookContext context,
  required io.Directory projectDirectory,
  required io.Directory buildDirectory,
  required void Function(int exitCode) exit,
}) async {
  final dartFrogDirectoryPath = path.join(projectDirectory.path, '.dart_frog');
  final dartFrogDirectory = io.Directory(dartFrogDirectoryPath);
  final bundlingProgress = context.logger.progress('Bundling sources');
  final tempDirectory = await io.Directory.systemTemp.createTemp();

  if (buildDirectory.existsSync()) {
    await buildDirectory.delete(recursive: true);
  }

  if (dartFrogDirectory.existsSync()) {
    await dartFrogDirectory.delete(recursive: true);
  }

  try {
    await copyPath(
      projectDirectory.path,
      '${tempDirectory.path}${path.separator}',
    );
    bundlingProgress.complete();
  } on Exception catch (error) {
    bundlingProgress.fail();
    context.logger.err('$error');
    return exit(1);
  }
  await copyPath(tempDirectory.path, buildDirectory.path);
}
