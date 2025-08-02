import 'dart:io';

Future<ProcessResult> runProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
  );

  if (result.exitCode != 0 || _isNotEmpty(result.stderr)) {
    final commandLine = [executable, ...arguments].join(' ');

    throw RunProcessException(
      '"$commandLine" exited with code ${result.exitCode}',
      processResult: result,
    );
  }

  return result;
}

bool _isNotEmpty(dynamic data) {
  if (data is String) return data.isNotEmpty;
  if (data is List) return data.isNotEmpty;
  return false;
}

class RunProcessException implements Exception {
  RunProcessException(this.message, {required this.processResult});

  final String message;

  final ProcessResult processResult;

  @override
  String toString() {
    return '''
$message
- pid: ${processResult.pid}
- stderr: ${processResult.stderr}
- stdout: ${processResult.stdout}
''';
  }
}
