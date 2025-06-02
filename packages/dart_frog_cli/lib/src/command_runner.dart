import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:dart_frog_cli/src/commands/commands.dart';
import 'package:dart_frog_cli/src/commands/update/update.dart';
import 'package:dart_frog_cli/src/version.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:pub_updater/pub_updater.dart';

/// Typedef for [io.exit].
typedef Exit = dynamic Function(int exitCode);

/// The package name.
const packageName = 'dart_frog_cli';

/// The executable name.
const executableName = 'dart_frog';

/// The executable description.
const executableDescription =
    'A fast, minimalistic backend framework for Dart.';

/// {@template dart_frog_command_runner}
/// A [CommandRunner] for the Dart Frog CLI.
/// {@endtemplate}
class DartFrogCommandRunner extends CompletionCommandRunner<int> {
  /// {@macro dart_frog_command_runner}
  DartFrogCommandRunner({
    Logger? logger,
    PubUpdater? pubUpdater,
    io.ProcessSignal? sigint,
    Exit? exit,
    io.Stdin? stdin,
  }) : _logger = logger ?? Logger(),
       _pubUpdater = pubUpdater ?? PubUpdater(),
       _sigint = sigint ?? io.ProcessSignal.sigint,
       _exit = exit ?? io.exit,
       stdin = stdin ?? io.stdin,
       super(executableName, executableDescription) {
    argParser.addFlags();
    addCommand(BuildCommand(logger: _logger));
    addCommand(CreateCommand(logger: _logger));
    addCommand(DevCommand(logger: _logger));
    addCommand(UpdateCommand(logger: _logger));
    addCommand(NewCommand(logger: _logger));
    addCommand(ListCommand(logger: _logger));
    addCommand(DaemonCommand(logger: _logger));
    addCommand(UninstallCommand(logger: _logger));
  }

  final Logger _logger;
  final PubUpdater _pubUpdater;
  final io.ProcessSignal _sigint;
  final Exit _exit;

  /// The [io.Stdin] instance to be used by the commands.
  final io.Stdin stdin;

  @override
  Future<int> run(Iterable<String> args) async {
    late final ArgResults argResults;
    try {
      argResults = parse(args);
    } on UsageException catch (error) {
      _logger.err('$error');
      return ExitCode.usage.code;
    }

    _sigint.watch().listen(_onSigint);

    late final int exitCode;
    try {
      exitCode = await runCommand(argResults) ?? ExitCode.success.code;
    } catch (error) {
      _logger.err('$error');
      exitCode = ExitCode.software.code;
    }

    if (argResults.command?.name != 'update' &&
        argResults.command?.name != 'completion') {
      await _checkForUpdates();
    }

    return exitCode;
  }

  Future<void> _onSigint(io.ProcessSignal signal) async {
    await _checkForUpdates();
    _exit(0);
  }

  Future<void> _checkForUpdates() async {
    _logger.detail('[updater] checking for updates...');
    try {
      final latestVersion = await _pubUpdater.getLatestVersion(packageName);
      _logger.detail('[updater] latest version is $latestVersion.');

      final isUpToDate = packageVersion == latestVersion;
      if (isUpToDate) {
        _logger.detail('[updater] no updates available.');
        return;
      }

      if (!isUpToDate) {
        _logger.detail('[updater] update available.');
        final changelogLink = lightCyan.wrap(
          styleUnderlined.wrap(
            link(
              uri: Uri.parse(
                'https://github.com/verygoodopensource/dart_frog/releases/tag/dart_frog_cli-v$latestVersion',
              ),
            ),
          ),
        );
        _logger
          ..info('')
          ..info('''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
${lightYellow.wrap('Changelog:')} $changelogLink
Run ${lightCyan.wrap('$executableName update')} to update''');
      }
    } catch (error, stackTrace) {
      _logger.detail('[updater] update check error.\n$error\n$stackTrace');
    } finally {
      _logger.detail('[updater] update check complete.');
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command?.name == 'completion') {
      await super.runCommand(topLevelResults);
      return ExitCode.success.code;
    }
    if (topLevelResults['version'] == true) {
      _logger.info(packageVersion);
      return ExitCode.success.code;
    }
    if (topLevelResults['verbose'] == true) {
      _logger.level = Level.verbose;
    }

    _logger.detail('[meta] $packageName $packageVersion');
    return super.runCommand(topLevelResults);
  }
}

extension on ArgParser {
  void addFlags() {
    addFlag('version', negatable: false, help: 'Print the current version.');
    addFlag('verbose', negatable: false, help: 'Output additional logs.');
  }
}
