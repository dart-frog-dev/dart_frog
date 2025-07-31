import 'dart:async';
import 'dart:io' as io;

import 'package:dart_frog_cli/src/command.dart';
import 'package:dart_frog_cli/src/commands/commands.dart';
import 'package:dart_frog_cli/src/commands/dev/templates/dart_frog_dev_server_bundle.dart';
import 'package:dart_frog_cli/src/dev_server_runner/dev_server_runner.dart';
import 'package:mason/mason.dart';

/// {@template dev_command}
/// `dart_frog dev` command which starts the dev server`.
/// {@endtemplate}
class DevCommand extends DartFrogCommand {
  /// {@macro dev_command}
  DevCommand({
    super.logger,
    GeneratorBuilder? generator,
    DevServerRunnerConstructor? devServerRunnerConstructor,
  }) : _generator = generator ?? MasonGenerator.fromBundle,
       _devServerRunnerConstructor =
           devServerRunnerConstructor ?? DevServerRunner.new {
    argParser
      ..addOption(
        'port',
        abbr: 'p',
        defaultsTo: '8080',
        help: 'Which port number the server should start on.',
      )
      ..addOption(
        'dart-vm-service-port',
        abbr: 'd',
        defaultsTo: _defaultDartVmServicePort,
        help: 'Which port number the dart vm service should listen on.',
      )
      ..addOption(
        'hostname',
        abbr: 'H',
        help: 'Which host name the server should bind to.',
        defaultsTo: 'localhost',
      );
  }

  static const _defaultDartVmServicePort = '8181';

  final GeneratorBuilder _generator;
  final DevServerRunnerConstructor _devServerRunnerConstructor;

  @override
  final String description = 'Run a local development server.';

  @override
  final String name = 'dev';

  StreamSubscription<List<int>>? _stdinSubscription;

  late final DevServerRunner _devServerRunner;

  void _startListeningForHelpers() {
    if (_stdinSubscription != null) return;
    if (!stdin.hasTerminal) return;

    // listen for the R key
    stdin
      ..echoMode = false
      ..lineMode = false;

    _stdinSubscription = stdin.listen(
      (event) {
        if (event.length == 1 &&
            (event.first == 'R'.codeUnitAt(0) ||
                event.first == 'r'.codeUnitAt(0))) {
          _devServerRunner.reload();
        }
      },
      onError: (dynamic error) {
        logger.err(error.toString());
        _stopListeningForHelpers();
      },
      cancelOnError: true,
      onDone: _stopListeningForHelpers,
    );

    logger.info('Press either R or r to reload');
  }

  void _stopListeningForHelpers() {
    _stdinSubscription?.cancel();
    _stdinSubscription = null;

    // The command may lose terminal after sigint, even though
    // the stdin subscription may have been created when the
    // devserver started.
    // That is why this check is made after the subscription
    // is canceled, if existent.
    if (!stdin.hasTerminal) return;

    stdin
      ..lineMode = true
      ..echoMode = true;
  }

  @override
  Future<int> run() async {
    final port = io.Platform.environment['PORT'] ?? results['port'] as String;

    final dartVmServicePort =
        (results['dart-vm-service-port'] as String?) ??
        _defaultDartVmServicePort;
    final generator = await _generator(dartFrogDevServerBundle);

    final hostname = results['hostname'] as String?;

    io.InternetAddress? ip;
    if (hostname != null && hostname != 'localhost') {
      ip = io.InternetAddress.tryParse(hostname);
      if (ip == null) {
        logger.err(
          'Invalid hostname "$hostname": must be a valid IPv4 or IPv6 address.',
        );
        return ExitCode.software.code;
      }
    }

    _devServerRunner = _devServerRunnerConstructor(
      devServerBundleGenerator: generator,
      logger: logger,
      workingDirectory: cwd,
      port: port,
      address: ip,
      dartVmServicePort: dartVmServicePort,
      onHotReloadEnabled: _startListeningForHelpers,
    );

    try {
      await _devServerRunner.start(results.rest);
      return (await _devServerRunner.exitCode).code;
    } catch (e) {
      logger.err(e.toString());
      return ExitCode.software.code;
    } finally {
      _stopListeningForHelpers();
    }
  }
}
