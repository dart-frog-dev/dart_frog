import 'dart:async';
import 'dart:io' as io;

import 'package:dart_frog_gen/dart_frog_gen.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

/// Typedef for [DirectoryWatcher.new].
typedef DirectoryWatcherBuilder = DirectoryWatcher Function(String directory);

/// Typedef for [RouteConfiguration] change callbacks.
typedef RouteConfigurationChanged =
    void Function(RouteConfiguration routeConfiguration);

/// Typedef for [RouteConfigurationWatcher.new].
typedef RouteConfigurationWatcherBuilder =
    RouteConfigurationWatcher Function({
      required Logger logger,
      required io.Directory workingDirectory,
      required RouteConfigurationChanged onRouteConfigurationChanged,
    });

/// Typedef for [buildRouteConfiguration]
typedef RouteConfigurationBuilder =
    RouteConfiguration Function(io.Directory directory);

/// {@template route_configuration_watcher}
/// Monitors a dart frog project for changes on its route configuration.
/// {@endtemplate}
class RouteConfigurationWatcher {
  /// {@macro route_configuration_watcher}
  RouteConfigurationWatcher({
    required this.logger,
    required this.workingDirectory,
    required this.onRouteConfigurationChanged,
    @visibleForTesting DirectoryWatcherBuilder? directoryWatcher,
    @visibleForTesting RouteConfigurationBuilder? routeConfigurationBuilder,
  }) : _directoryWatcher = directoryWatcher ?? DirectoryWatcher.new,
       _routeConfigurationBuilder =
           routeConfigurationBuilder ?? buildRouteConfiguration;

  /// [Logger] instance used to wrap stdout.
  final Logger logger;

  /// The working directory of the dart_frog project.
  final io.Directory workingDirectory;

  /// Callback for when the route configuration changes.
  final RouteConfigurationChanged onRouteConfigurationChanged;

  final Completer<ExitCode> _exitCodeCompleter = Completer<ExitCode>();

  StreamSubscription<WatchEvent>? _watcherSubscription;

  bool _isRunning = false;

  final DirectoryWatcherBuilder _directoryWatcher;
  final RouteConfigurationBuilder _routeConfigurationBuilder;

  /// A [Future] that completes when the watcher stops.
  Future<ExitCode> get exitCode => _exitCodeCompleter.future;

  /// Whether the dev server has been started and stopped.
  bool get isCompleted => _exitCodeCompleter.isCompleted;

  /// Whether the dev server is watching for file changes.
  bool get isWatching => _watcherSubscription != null;

  /// Whether the watcher is running or set to run.
  bool get isRunning => _isRunning;

  /// Starts the watcher.
  Future<void> start() async {
    if (isCompleted) {
      throw DartFrogRouteConfigurationWatcherException(
        'Cannot start a route config watcher after it has been stopped.',
      );
    }

    if (isRunning) {
      throw DartFrogRouteConfigurationWatcherException(
        'Cannot start a route config watcher while already running.',
      );
    }

    _isRunning = true;
    logger.info('Starting route configuration watcher...');

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
        .listen((_) => _regenerateRouteConfiguration());

    unawaited(
      _watcherSubscription!.asFuture<void>().then((value) async {
        await _watcherSubscription?.cancel();
        _isRunning = false;
        _exitCodeCompleter.complete(ExitCode.success);
      }),
    );
  }

  /// Stops the watcher.
  Future<void> stop() async {
    if (isCompleted) {
      return;
    }

    logger.detail('[watcher] cancelling subscription...');
    await _watcherSubscription?.cancel();
    _watcherSubscription = null;
    _isRunning = false;
    logger.detail('[watcher] cancelling subscription complete.');

    _exitCodeCompleter.complete(ExitCode.success);
  }

  /// Force a route config regeneration as if there was a file system change
  /// that affected the watcher.
  RouteConfiguration? forceRouteConfigurationRegeneration() {
    if (!isRunning) {
      return null;
    }

    return _regenerateRouteConfiguration();
  }

  RouteConfiguration? _regenerateRouteConfiguration() {
    final RouteConfiguration routeConfiguration;
    final projectDirectory = workingDirectory;
    try {
      routeConfiguration = _routeConfigurationBuilder(projectDirectory);
    } catch (error) {
      logger.err('$error');
      return null;
    }

    onRouteConfigurationChanged(routeConfiguration);
    return routeConfiguration;
  }
}

/// {@template dart_frog_route_configuration_watcher_exception}
/// Thrown when an error occurs while running the route config watcher.
/// {@endtemplate}
class DartFrogRouteConfigurationWatcherException implements Exception {
  /// {@macro dart_frog_route_configuration_watcher_exception}
  DartFrogRouteConfigurationWatcherException(this.message);

  /// The exception message.
  final String message;

  @override
  String toString() => message;
}
