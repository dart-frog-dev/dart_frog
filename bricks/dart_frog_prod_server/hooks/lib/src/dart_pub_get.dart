import 'dart:io' as io;

import 'package:mason/mason.dart';

typedef ProcessRunner = Future<io.ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String workingDirectory,
  bool runInShell,
});

Future<void> dartPubGet(
  HookContext context, {
  required String workingDirectory,
  required ProcessRunner runProcess,
  required void Function(int exitCode) exit,
  String message = 'Installing dependencies',
}) async {
  final progress = context.logger.progress(message);
  try {
    final result = await runProcess(
      'dart',
      ['pub', 'get'],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    progress.complete();

    if (result.exitCode != 0) {
      context.logger.err('${result.stderr}');
      return exit(result.exitCode);
    }
  } on io.ProcessException catch (error) {
    context.logger.err(error.message);
    return exit(error.errorCode);
  }
}
