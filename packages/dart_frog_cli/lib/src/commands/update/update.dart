import 'dart:io';

import 'package:dart_frog_cli/src/command.dart';
import 'package:dart_frog_cli/src/command_runner.dart';
import 'package:dart_frog_cli/src/version.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:pub_updater/pub_updater.dart';

/// {@template update_command}
/// `dart_frog update` command which updates the dart_frog_cli.
/// {@endtemplate}
class UpdateCommand extends DartFrogCommand {
  /// {@macro update_command}
  UpdateCommand({required Logger logger, PubUpdater? pubUpdater})
    : _logger = logger,
      _pubUpdater = pubUpdater ?? PubUpdater() {
    argParser.addFlag(
      'verify-only',
      help: 'Check if an update is available, without committing to update.',
      negatable: false,
    );
  }

  final Logger _logger;
  final PubUpdater _pubUpdater;

  @override
  String get description => 'Update the Dart Frog CLI.';

  @override
  String get name => 'update';

  @override
  final String invocation = 'dart_frog update';

  @override
  Future<int> run() async {
    final verifyOnly = results['verify-only'] as bool;

    final updateCheckProgress = _logger.progress('Checking for updates');
    late final String latestVersion;
    try {
      latestVersion = await _pubUpdater.getLatestVersion(packageName);
    } catch (error) {
      updateCheckProgress.fail();
      _logger.err('$error');
      return ExitCode.software.code;
    }
    updateCheckProgress.complete('Checked for updates');

    final isUpToDate = packageVersion == latestVersion;
    if (isUpToDate) {
      _logger.info('$packageName is already at the latest version.');
      return ExitCode.success.code;
    } else if (verifyOnly) {
      _logger
        ..info('A new version of $packageName is available.\n')
        ..info(styleBold.wrap('The latest version: $latestVersion'))
        ..info('Your current version: $packageVersion\n')
        ..info('To update now, run "$executableName update".');
      return ExitCode.success.code;
    }

    final updateProgress = _logger.progress('Updating to $latestVersion');
    late ProcessResult result;
    try {
      result = await _pubUpdater.update(
        packageName: packageName,
        versionConstraint: latestVersion,
      );
    } catch (error) {
      updateProgress.fail();
      _logger.err('$error');
      return ExitCode.software.code;
    }
    if (result.exitCode != ExitCode.success.code) {
      updateProgress.fail();
      _logger.err('Error updating Dart Frog CLI: ${result.stderr}');
      return ExitCode.software.code;
    }
    updateProgress.complete('Updated to $latestVersion');

    return ExitCode.success.code;
  }
}
