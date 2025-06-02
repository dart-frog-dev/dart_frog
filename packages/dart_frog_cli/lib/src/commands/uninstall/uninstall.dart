import 'package:args/command_runner.dart';
import 'package:dart_frog_cli/src/command_runner.dart';
import 'package:mason/mason.dart' hide packageVersion;

/// {@template uninstall_command}
/// `dart_frog uninstall` command which explains how to uninstall
/// the dart_frog_cli.
/// {@endtemplate}
class UninstallCommand extends Command<int> {
  /// {@macro uninstall_command}
  UninstallCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get description => 'Explains how to uninstall the Dart Frog CLI.';

  @override
  String get name => 'uninstall';

  @override
  Future<int> run() async {
    final docs = link(
      uri: Uri.parse('https://dartfrog.vgv.dev/docs/overview#uninstalling-'),
    );
    _logger.info(
      'For instructions on how to uninstall $packageName completely, check out:'
      '\n$docs',
    );

    return ExitCode.success.code;
  }
}
