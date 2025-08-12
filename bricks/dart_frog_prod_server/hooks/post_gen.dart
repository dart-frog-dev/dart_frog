import 'dart:async';
import 'dart:io' as io;

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:mason/mason.dart' show HookContext, lightCyan;
import 'package:path/path.dart' as path;

Future<void> run(HookContext context) => postGen(context);

Future<void> postGen(
  HookContext context, {
  io.Directory? directory,
  ProcessRunner runProcess = io.Process.run,
  void Function(int exitCode) exit = defaultExit,
}) async {
  final projectDirectory = directory ?? io.Directory.current;
  final buildDirectoryPath = path.join(projectDirectory.path, 'build');

  await dartPubGet(
    context,
    workingDirectory: buildDirectoryPath,
    runProcess: runProcess,
    exit: exit,
  );

  final relativeBuildPath = path.relative(buildDirectoryPath);
  context.logger
    ..info('')
    ..success('Created a production build!')
    ..info('')
    ..info('Start the production server by running:')
    ..info('')
    ..info(
      '''${lightCyan.wrap('dart ${path.join(relativeBuildPath, 'bin', 'server.dart')}')}''',
    );
}
