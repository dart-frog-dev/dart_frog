import 'dart:io';

import 'helpers.dart';

Future<void> dartFrogBuild({required Directory directory}) async {
  await runProcess(
    'dart_frog',
    ['build'],
    workingDirectory: directory.path,
    runInShell: true,
  );
}
