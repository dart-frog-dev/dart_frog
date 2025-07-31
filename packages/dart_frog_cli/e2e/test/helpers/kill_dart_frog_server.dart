import 'dart:io';

import 'helpers.dart';

Future<void> killDartFrogServer(int pid, {int port = 8080}) async {
  if (Platform.isWindows) {
    await runProcess('taskkill', [
      '/F',
      '/T',
      '/PID',
      '$pid',
    ], runInShell: true);

    return;
  }

  if (Platform.isLinux) {
    await runProcess('fuser', ['-n', 'tcp', '-k', '$port']);

    return;
  }

  if (Platform.isMacOS) {
    await runProcess('pkill', ['-f', 'dart_frog']);

    return;
  }
}
