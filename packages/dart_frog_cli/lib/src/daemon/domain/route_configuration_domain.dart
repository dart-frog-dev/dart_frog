import 'dart:async';
import 'dart:io' as io;

import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:dart_frog_cli/src/route_configuration_watcher/route_configuration_watcher.dart';
import 'package:meta/meta.dart';

/// {@template route_configuration_domain}
/// A [DomainBase] which includes operations for starting and stopping
/// [RouteConfigurationWatcher]s.
/// {@endtemplate}
class RouteConfigurationDomain extends DomainBase {
  /// {@macro route_configuration_domain}
  RouteConfigurationDomain(
    super.daemon, {
    @visibleForTesting super.getId,
    @visibleForTesting
    RouteConfigurationWatcherBuilder? routeConfigurationWatcherBuilder,
  }) : _routeConfigWatcherBuilder =
           routeConfigurationWatcherBuilder ?? RouteConfigurationWatcher.new {
    addHandler('watcherStart', _watcherStart);
    addHandler(
      'watcherGenerateRouteConfiguration',
      _watcherGenerateRouteConfiguration,
    );
    addHandler('watcherStop', _watcherStop);
  }

  @override
  String get domainName => 'route_configuration';

  final _routeConfigurationWatchers = <String, RouteConfigurationWatcher>{};

  final RouteConfigurationWatcherBuilder _routeConfigWatcherBuilder;

  Future<DaemonResponse> _watcherStart(DaemonRequest request) async {
    final workingDirectory = request.getParam<String>('workingDirectory');

    final watcherId = getId();

    final logger = DaemonLogger(
      domain: domainName,
      params: {
        'watcherId': watcherId,
        'requestId': request.id,
        'workingDirectory': workingDirectory,
      },
      sendEvent: daemon.sendEvent,
      idGenerator: getId,
    );

    final routeConfigWatcher = _routeConfigWatcherBuilder(
      logger: logger,
      workingDirectory: io.Directory(workingDirectory),
      onRouteConfigurationChanged: (routeConfiguration) {
        daemon.sendEvent(
          DaemonEvent(
            domain: domainName,
            event: 'changed',
            params: {
              'watcherId': watcherId,
              'requestId': request.id,
              'routeConfiguration': routeConfiguration.toJson(),
            },
          ),
        );
      },
    );

    _routeConfigurationWatchers[watcherId] = routeConfigWatcher;

    try {
      await routeConfigWatcher.start();

      daemon.sendEvent(
        DaemonEvent(
          domain: domainName,
          event: 'watcherStart',
          params: {
            'watcherId': watcherId,
            'requestId': request.id,
            'workingDirectory': workingDirectory,
          },
        ),
      );
    } catch (e) {
      return DaemonResponse.error(
        id: request.id,
        error: {'watcherId': watcherId, 'message': e.toString()},
      );
    }

    routeConfigWatcher.exitCode.then((exitCode) {
      daemon.sendEvent(
        DaemonEvent(
          domain: domainName,
          event: 'watcherExit',
          params: {
            'watcherId': watcherId,
            'requestId': request.id,
            'workingDirectory': workingDirectory,
            'exitCode': exitCode.code,
          },
        ),
      );
    }).ignore();

    // Queue up a regeneration of the route config so that it happens after the
    // daemon has responded to the client.
    Timer.run(routeConfigWatcher.forceRouteConfigurationRegeneration);

    return DaemonResponse.success(
      id: request.id,
      result: {'watcherId': watcherId},
    );
  }

  Future<DaemonResponse> _watcherGenerateRouteConfiguration(
    DaemonRequest request,
  ) async {
    final watcherId = request.getParam<String>('watcherId');

    final watcher = _routeConfigurationWatchers[watcherId];
    if (watcher == null) {
      return DaemonResponse.error(
        id: request.id,
        error: {'watcherId': watcherId, 'message': 'Watcher not found'},
      );
    }

    final routeConfiguration = watcher.forceRouteConfigurationRegeneration();

    if (routeConfiguration == null) {
      return DaemonResponse.error(
        id: request.id,
        error: {
          'watcherId': watcherId,
          'message': 'Could not regenerate route configuration',
        },
      );
    }

    return DaemonResponse.success(
      id: request.id,
      result: {
        'watcherId': watcherId,
        'routeConfiguration': routeConfiguration.toJson(),
      },
    );
  }

  Future<DaemonResponse> _watcherStop(DaemonRequest request) async {
    final watcherId = request.getParam<String>('watcherId');

    final watcher = _routeConfigurationWatchers.remove(watcherId);
    if (watcher == null) {
      return DaemonResponse.error(
        id: request.id,
        error: {'watcherId': watcherId, 'message': 'Watcher not found'},
      );
    }

    try {
      await watcher.stop();

      final exitCode = await watcher.exitCode;

      return DaemonResponse.success(
        id: request.id,
        result: {'watcherId': watcherId, 'exitCode': exitCode.code},
      );
    } catch (e) {
      if (!watcher.isCompleted) {
        _routeConfigurationWatchers[watcherId] = watcher;
      }
      return DaemonResponse.error(
        id: request.id,
        error: {
          'watcherId': watcherId,
          'message': e.toString(),
          'finished': watcher.isCompleted,
        },
      );
    }
  }

  @override
  Future<void> dispose() async {
    for (final watcher in _routeConfigurationWatchers.values) {
      await watcher.stop();
    }
    _routeConfigurationWatchers.clear();
  }
}
