import 'dart:async';
import 'dart:io' as io;

import 'package:mason/mason.dart' show HookContext, lightCyan;
import 'package:path/path.dart' as path;

Future<void> run(HookContext context) => postGen(context);

Future<void> postGen(
  HookContext context, {
  io.Directory? directory,
}) async {
  final projectDirectory = directory ?? io.Directory.current;
  final buildDirectoryPath = path.join(projectDirectory.path, 'build');
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
