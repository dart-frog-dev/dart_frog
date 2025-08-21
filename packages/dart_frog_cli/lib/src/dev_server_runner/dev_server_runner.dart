import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dart_frog_cli/src/dev_server_runner/restorable_directory_generator_target.dart';
import 'package:dart_frog_cli/src/runtime_compatibility.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

/// Typedef for [io.Process.start].
typedef ProcessStart = Future<io.Process> Function(
  String executable,
  List<String> arguments, {
  bool runInShell,
});

/// Typedef for [io.Process.run].
typedef ProcessRun = Future<io.ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// Typedef for [DirectoryWatcher.new].
typedef DirectoryWatcherBuilder = DirectoryWatcher Function(
  String directory,
);

/// Regex for detecting warnings in the output of `dart run`.
final _warningRegex = RegExp(r'^.*:\d+:\d+: Warning: .*', multiLine: true);

/// Regex for detecting when the `dart_frog dev` fails to run for using a
/// Dart VM Service with an already used port.
final _dartVmServiceAlreadyInUseErrorRegex = RegExp(
  '^Could not start the VM service: localhost:.* is already in use.',
  multiLine: true,
);

/// Typedef for [DevServerRunner.new].
typedef DevServerRunnerConstructor = DevServerRunner Function({
  required Logger logger,
  required String port,
  required io.InternetAddress? address,
  required MasonGenerator devServerBundleGenerator,
  required String dartVmServicePort,
  required io.Directory workingDirectory,
  void Function()? onHotReloadEnabled,
});

/// {@template dev_server_runner}
/// A class that manages a local development server process lifecycle.
///
/// The [DevServerRunner] is responsible for:
/// - Generating the dev server runtime code.
/// - Starting the dev server process.
/// - Watching for file changes.
/// - Restarting the dev server process when files change.
/// - Stopping the dev server process when requested or under external
/// circumstances (server process killed or watcher stopped).
///
/// After stopped, a [DevServerRunner] instance cannot be restarted.
/// {@endtemplate}
class DevServerRunner {
  /// {@macro dev_server_runner}
  DevServerRunner({
    required this.logger,
    required this.port,
    required this.address,
    required this.devServerBundleGenerator,
    required this.dartVmServicePort,
    required this.workingDirectory,
    this.onHotReloadEnabled,
    @visibleForTesting DirectoryWatcherBuilder? directoryWatcher,
    @visibleForTesting
    RestorableDirectoryGeneratorTargetBuilder? generatorTarget,
    @visibleForTesting bool? isWindows,
    @visibleForTesting io.ProcessSignal? sigint,
    @visibleForTesting ProcessStart? startProcess,
    @visibleForTesting ProcessRun? runProcess,
    @visibleForTesting
    RuntimeCompatibilityCallback? runtimeCompatibilityCallback,
  })  : _directoryWatcher = directoryWatcher ?? DirectoryWatcher.new,
        _isWindows = isWindows ?? io.Platform.isWindows,
        _sigint = sigint ?? io.ProcessSignal.sigint,
        _startProcess = startProcess ?? io.Process.start,
        _runProcess = runProcess ?? io.Process.run,
        _generatorTarget =
            generatorTarget ?? RestorableDirectoryGeneratorTarget.new,
        _ensureRuntimeCompatibility =
            runtimeCompatibilityCallback ?? ensureRuntimeCompatibility,
        assert(port.isNotEmpty, 'port cannot be empty'),
        assert(
          dartVmServicePort.isNotEmpty,
          'dartVmServicePort cannot be empty',
        );

  /// [Logger] instance used to wrap stdout.
  final Logger logger;

  /// Which port number the server should start on.
  final String port;

  /// Which host the server should start on.
  ///
  /// It will default to localhost if empty.
  final io.InternetAddress? address;

  /// Which port number the dart vm service should listen on.
  final String dartVmServicePort;

  /// The [MasonGenerator] used to generate the dev server runtime code.
  final MasonGenerator devServerBundleGenerator;

  /// The working directory of the dart_frog project.
  final io.Directory workingDirectory;

  /// Callback for when hot reload is enabled.
  final void Function()? onHotReloadEnabled;

  final DirectoryWatcherBuilder _directoryWatcher;
  final ProcessStart _startProcess;
  final ProcessRun _runProcess;
  final RestorableDirectoryGeneratorTargetBuilder _generatorTarget;
  final bool _isWindows;
  final io.ProcessSignal _sigint;
  final RuntimeCompatibilityCallback _ensureRuntimeCompatibility;

  late final _generatedDirectory = io.Directory(
    path.join(workingDirectory.path, '.dart_frog'),
  );
  late final _target = _generatorTarget(_generatedDirectory, logger: logger);

  var _isReloading = false;
  io.Process? _serverProcess;
  StreamSubscription<WatchEvent>? _watcherSubscription;

  /// Whether the dev server is running.
  bool get isServerRunning => _serverProcess != null;

  /// Whether the dev server is watching for file changes.
  bool get isWatching => _watcherSubscription != null;

  /// Whether the dev server has been started and stopped.
  bool get isCompleted => _exitCodeCompleter.isCompleted;

  final Completer<ExitCode> _exitCodeCompleter = Completer<ExitCode>();

  /// A [Future] that completes when the dev server stops.
  ///
  /// The [Future] will complete with the [ExitCode] indicating the conditions
  /// under which the dev server ended.
  Future<ExitCode> get exitCode => _exitCodeCompleter.future;

  Future<void> _codegen() async {
    logger.detail('[codegen] running pre-gen...');
    final address = this.address;
    logger.detail('Starting development server on host ${address?.address}');
    var vars = <String, dynamic>{
      'port': port,
      if (address != null) 'host': address.address,
    };
    await devServerBundleGenerator.hooks.preGen(
      vars: vars,
      workingDirectory: workingDirectory.path,
      onVarsChanged: (v) => vars = v,
    );

    logger.detail('[codegen] running generate...');
    await devServerBundleGenerator.generate(
      _target,
      vars: vars,
      fileConflictResolution: FileConflictResolution.overwrite,
    );
    logger.detail('[codegen] complete.');
  }

  Future<void> _reload([bool verbose = false]) async {
    final void Function(String) log;
    if (verbose) {
      log = logger.info;
    } else {
      log = logger.detail;
    }

    log('[codegen] reloading...');
    _isReloading = true;
    await _codegen();
    _isReloading = false;
    log('[codegen] reload complete.');
  }

  // Internal method to kill the server process.
  // Make sure to call `stop` after calling this method to also stop the
  // watcher.
  Future<void> _killServerProcess() async {
    _isReloading = false;
    final process = _serverProcess;
    if (process == null) {
      return;
    }
    logger.detail('[process] killing process...');
    if (_isWindows) {
      logger.detail('[process] taskkill /F /T /PID ${process.pid}');
      await _runProcess('taskkill', ['/F', '/T', '/PID', '${process.pid}']);
    } else {
      logger.detail('[process] process.kill()...');
      process.kill();
    }
    _serverProcess = null;
    logger.detail('[process] killing process complete.');
  }

  // Internal method to cancel the watcher subscription.
  // Make sure to call `stop` after calling this method to also stop the
  // server process.
  Future<void> _cancelWatcherSubscription() async {
    if (!isWatching) {
      return;
    }
    logger.detail('[watcher] cancelling subscription...');
    await _watcherSubscription!.cancel();
    _watcherSubscription = null;
    logger.detail('[watcher] cancelling subscription complete.');
  }

  /// Starts the development server and a [DirectoryWatcher] subscription
  /// that will regenerate the dev server code when files change.
  ///
  /// This method will throw a [DartFrogDevServerException] if called while
  /// the dev server has been started.
  ///
  /// This method will throw a [DartFrogDevServerException] if called after
  /// [stop] has been called.
  ///
  /// The [arguments] are optional and usually expected to be those from
  /// `ArgResults.rest`; since a `--` signals the **end of options** and
  /// disables further option processing from `dart_frog dev`. Any [arguments]
  /// after the `--` are passed into the [Dart tool](https://dart.dev/tools/dart-tool)
  /// process.
  ///
  /// For example, you could use the `--` to enable [experimental flags](https://dart.dev/tools/experiment-flags)
  /// such as macros by doing `dart_frog dev -- --enable-experiment=macros`.
  Future<void> start([List<String> arguments = const []]) async {
    if (isCompleted) {
      throw DartFrogDevServerException(
        'Cannot start a dev server after it has been stopped.',
      );
    }

    if (isServerRunning) {
      throw DartFrogDevServerException(
        'Cannot start a dev server while already running.',
      );
    }

    _ensureRuntimeCompatibility(workingDirectory);

    Future<void> serve() async {
      var isHotReloadingEnabled = false;
      final enableVmServiceFlag = '--enable-vm-service=$dartVmServicePort';

      final serverDartFilePath = path.join(
        _generatedDirectory.absolute.path,
        'server.dart',
      );

      logger.detail(
        '''[process] dart $enableVmServiceFlag $serverDartFilePath ${arguments.join(' ')}''',
      );

      final process = _serverProcess = await _startProcess(
        'dart',
        [
          enableVmServiceFlag,
          '--enable-asserts',
          ...arguments,
          serverDartFilePath,
        ],
        runInShell: true,
      );

      // On Windows listen for CTRL-C and use taskkill to kill
      // the spawned process along with any child processes.
      // https://github.com/dart-lang/sdk/issues/22470
      if (_isWindows) {
        _sigint.watch().listen((_) {
          // Do not await on sigint
          _killServerProcess().ignore();
          stop();
        });
      }

      var hasError = false;
      process.stderr.listen((data) async {
        hasError = true;

        if (_isReloading) return;

        final message = utf8.decode(data).trim();
        if (message.isEmpty) return;

        final isDartVMServiceAlreadyInUseError =
            _dartVmServiceAlreadyInUseErrorRegex.hasMatch(message);
        final isSDKWarning = _warningRegex.hasMatch(message);

        if (isDartVMServiceAlreadyInUseError) {
          logger.err(
            '$message '
            '''Try specifying a different port using the `--dart-vm-service-port` argument when running `dart_frog dev`.''',
          );
        } else if (isSDKWarning) {
          // Do not kill the process if the error is a warning from the SDK.
          logger.warn(message);
        } else {
          logger.err(message);
        }

        if ((!isHotReloadingEnabled && !isSDKWarning) ||
            isDartVMServiceAlreadyInUseError) {
          await _killServerProcess();
          const exitCode = ExitCode.software;
          logger.detail('[process] exit(${exitCode.code})');
          await stop(exitCode);
          return;
        }

        await _target.rollback();
      });

      process.stdout.listen((data) {
        final message = utf8.decode(data).trim();
        final containsHotReload = message.contains('[hotreload]');
        if (message.isNotEmpty) logger.info(message);
        if (containsHotReload) {
          isHotReloadingEnabled = true;
          onHotReloadEnabled?.call();
        }
        final shouldCacheSnapshot = containsHotReload && !hasError;
        if (shouldCacheSnapshot) _target.cacheLatestSnapshot();
        hasError = false;
      });

      process.exitCode.then((code) async {
        if (isCompleted) return;
        logger
          ..info('[process] Server process has been terminated')
          ..detail('[process] exit($code)');
        await _killServerProcess();
        await stop(ExitCode.unavailable);
      }).ignore();
    }

    final progress = logger.progress('Serving');
    await _codegen();
    await serve();

    final hostAddress = address?.address ?? 'localhost';

    final localhost = link(uri: Uri.parse('http://$hostAddress:$port'));
    progress.complete('Running on $localhost');

    final cwdPath = workingDirectory.path;
    final entrypoint = path.join(cwdPath, 'main.dart');
    final pubspec = path.join(cwdPath, 'pubspec.yaml');
    final public = path.join(cwdPath, 'public');
    final routes = path.join(cwdPath, 'routes');

    bool shouldReload(WatchEvent event) {
      logger.detail('[watcher] $event');
      return path.equals(entrypoint, event.path) ||
          path.equals(pubspec, event.path) ||
          path.isWithin(routes, event.path) ||
          path.isWithin(public, event.path);
    }

    final watcher = _directoryWatcher(path.join(cwdPath));
    _watcherSubscription = watcher.events
        .where(shouldReload)
        .debounce(Duration.zero)
        .listen((_) => _reload());

    _watcherSubscription!.asFuture<void>().then((_) async {
      await _cancelWatcherSubscription();
      await stop();
    }).catchError((_) async {
      await _cancelWatcherSubscription();
      await stop(ExitCode.software);
    }).ignore();
  }

  /// Stops the development server and the watcher then
  /// completes [DevServerRunner.exitCode] with the given [exitCode].
  ///
  /// If [exitCode] is not provided, it defaults to [ExitCode.success].
  ///
  /// After calling [stop], the dev server cannot be restarted.
  ///
  /// This can be called internally if the server process is killed or if the
  /// watcher stops watching.
  Future<void> stop([ExitCode exitCode = ExitCode.success]) async {
    if (isCompleted) {
      return;
    }

    if (isWatching) {
      await _cancelWatcherSubscription();
    }
    if (isServerRunning) {
      await _killServerProcess();
    }

    _exitCodeCompleter.complete(exitCode);
  }

  /// Regenerates the dev server code and sends a hot reload signal to the
  /// server.
  Future<void> reload() async {
    if (isCompleted || !isServerRunning || _isReloading) return;
    return _reload(true);
  }
}

/// {@template dart_frog_dev_server_exception}
/// Exception thrown when the dev server fails to start.
/// {@endtemplate}
class DartFrogDevServerException implements Exception {
  /// {@macro dart_frog_dev_server_exception}
  DartFrogDevServerException(this.message);

  /// The exception message.
  final String message;

  @override
  String toString() => message;
}
