import 'dart:io';

import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../helpers/helpers.dart';

/// Objectives:
///
/// * Generate a new Dart Frog project via `dart_frog create`
/// * Start the daemon
/// * Start a route configuration watcher
/// * Create a new route on the project and verify new route configuration
/// * Generate a route configuration
/// * Create a rogue route and verify new route configuration
/// * Stop the route configuration watcher
/// * Stop the daemon
void main() {
  const projectName = 'example';
  final tempDirectory = Directory.systemTemp.createTempSync();
  final projectDirectory = Directory(
    path.join(tempDirectory.path, projectName),
  );

  late Process daemonProcess;

  late final DaemonStdioHelper daemonStdio;

  var requestCount = 0;

  late String projectWatcherId;

  setUpAll(() async {
    await dartFrogCreate(projectName: projectName, directory: tempDirectory);
    daemonProcess = await dartFrogDaemonStart();

    daemonStdio = DaemonStdioHelper(daemonProcess);
    addTearDown(() async {
      daemonProcess.kill(ProcessSignal.sigkill);
      daemonStdio.dispose();
    });

    await daemonStdio.awaitForDaemonEvent('daemon.ready');
  });

  group('route configuration domain', () {
    test('start route configuration watcher', () async {
      final response = await daemonStdio.sendDaemonRequest(
        DaemonRequest(
          id: '${++requestCount}',
          domain: 'route_configuration',
          method: 'watcherStart',
          params: {'workingDirectory': projectDirectory.path},
        ),
      );

      expect(response.isSuccess, isTrue);
      projectWatcherId = response.result!['watcherId'] as String;

      final event = await daemonStdio.awaitForDaemonEvent(
        'route_configuration.changed',
        withParamsThat: containsPair('watcherId', projectWatcherId),
        timeout: const Duration(seconds: 5),
      );

      final routeConfiguration =
          event.params?['routeConfiguration'] as Map<String, dynamic>;
      final routeConfigurationEndpoints =
          routeConfiguration['endpoints'] as Map<String, dynamic>;
      final routeConfigurationMiddleware =
          routeConfiguration['middleware'] as List<dynamic>;
      final routeConfigurationRogueRoutes =
          routeConfiguration['rogueRoutes'] as List<dynamic>;

      expect(routeConfigurationEndpoints.keys.toList(), containsAll(['/']));
      expect(routeConfigurationMiddleware, isEmpty);
      expect(routeConfigurationRogueRoutes, isEmpty);
    });

    test('create new route', () async {
      await dartFrogNewRoute('new_route', directory: projectDirectory);

      final event = await daemonStdio.awaitForDaemonEvent(
        'route_configuration.changed',
        withParamsThat: containsPair('watcherId', projectWatcherId),
        timeout: const Duration(seconds: 5),
      );

      final routeConfiguration =
          event.params?['routeConfiguration'] as Map<String, dynamic>;
      final routeConfigurationEndpoints =
          routeConfiguration['endpoints'] as Map<String, dynamic>;
      final routeConfigurationMiddleware =
          routeConfiguration['middleware'] as List<dynamic>;
      final routeConfigurationRogueRoutes =
          routeConfiguration['rogueRoutes'] as List<dynamic>;

      expect(
        routeConfigurationEndpoints.keys.toList(),
        equals(['/new_route', '/']),
      );
      expect(routeConfigurationMiddleware, isEmpty);
      expect(routeConfigurationRogueRoutes, isEmpty);
    });

    test('create new middleware', () async {
      await dartFrogNewMiddleware('new_route', directory: projectDirectory);

      // Creating a middleware ath that route will case some files to move
      // around before the middleware file is created. Therefore, we have to
      // wait for the logger event that indicates the middleware file was
      // created.
      await daemonStdio.awaitForDaemonEvent(
        'route_configuration.loggerDetail',
        withParamsThat: allOf(
          containsPair('watcherId', projectWatcherId),
          containsPair('requestId', '1'),
          containsPair(
            'message',
            allOf(
              startsWith('[watcher] add'),
              endsWith(path.join('new_route', '_middleware.dart')),
            ),
          ),
        ),
        timeout: const Duration(seconds: 5),
      );

      final event = await daemonStdio.awaitForDaemonEvent(
        'route_configuration.changed',
        withParamsThat: containsPair('watcherId', projectWatcherId),
        timeout: const Duration(seconds: 5),
      );

      final routeConfiguration =
          event.params?['routeConfiguration'] as Map<String, dynamic>;
      final routeConfigurationEndpoints =
          routeConfiguration['endpoints'] as Map<String, dynamic>;
      final routeConfigurationMiddleware =
          routeConfiguration['middleware'] as List<dynamic>;
      final routeConfigurationRogueRoutes =
          routeConfiguration['rogueRoutes'] as List<dynamic>;

      expect(
        routeConfigurationEndpoints.keys.toList(),
        containsAll(['/new_route', '/']),
      );
      expect(
        (routeConfigurationMiddleware.first as Map<String, dynamic>)['path'],
        '../routes/new_route/_middleware.dart',
      );
      expect(routeConfigurationRogueRoutes, isEmpty);
    });

    test('ask for route config generation', () async {
      final response = await daemonStdio.sendDaemonRequest(
        DaemonRequest(
          id: '${requestCount++}',
          domain: 'route_configuration',
          method: 'watcherGenerateRouteConfiguration',
          params: {'watcherId': projectWatcherId},
        ),
      );

      expect(response.isSuccess, isTrue);
      final routeConfiguration =
          response.result?['routeConfiguration'] as Map<String, dynamic>;
      final routeConfigurationEndpoints =
          routeConfiguration['endpoints'] as Map<String, dynamic>;
      final routeConfigurationMiddleware =
          routeConfiguration['middleware'] as List<dynamic>;
      final routeConfigurationRogueRoutes =
          routeConfiguration['rogueRoutes'] as List<dynamic>;

      expect(
        routeConfigurationEndpoints.keys.toList(),
        containsAll(['/new_route', '/']),
      );
      expect(
        (routeConfigurationMiddleware.first as Map<String, dynamic>)['path'],
        '../routes/new_route/_middleware.dart',
      );
      expect(routeConfigurationRogueRoutes, isEmpty);
    });

    test('create a rogue route', () async {
      await dartFrogNewRoute(
        'rogue_route/sub_route',
        directory: projectDirectory,
      );

      File(
        path.join(projectDirectory.path, 'routes', 'rogue_route.dart'),
      ).createSync();

      await daemonStdio.awaitForDaemonEvent(
        'route_configuration.loggerDetail',
        withParamsThat: allOf(
          containsPair('watcherId', projectWatcherId),
          containsPair('requestId', '1'),
          containsPair(
            'message',
            allOf(startsWith('[watcher] add'), endsWith('rogue_route.dart')),
          ),
        ),
        timeout: const Duration(seconds: 5),
      );

      final event = await daemonStdio.awaitForDaemonEvent(
        'route_configuration.changed',
        withParamsThat: containsPair('watcherId', projectWatcherId),
        timeout: const Duration(seconds: 5),
      );

      final routeConfiguration =
          event.params?['routeConfiguration'] as Map<String, dynamic>;
      final routeConfigurationRogueRoutes =
          routeConfiguration['rogueRoutes'] as List<dynamic>;

      expect(routeConfigurationRogueRoutes.length, equals(1));
      expect(
        (routeConfigurationRogueRoutes.first as Map<String, dynamic>)['path'],
        equals('../routes/rogue_route.dart'),
      );
    });

    test('staggered-stop watcher', () async {
      final (response1, response2) = await daemonStdio
          .sendStaggeredDaemonRequest((
            DaemonRequest(
              id: '${requestCount++}',
              domain: 'route_configuration',
              method: 'watcherStop',
              params: {'watcherId': projectWatcherId},
            ),
            DaemonRequest(
              id: '${requestCount++}',
              domain: 'route_configuration',
              method: 'watcherStop',
              params: {'watcherId': projectWatcherId},
            ),
          ));

      expect(response1.isSuccess, isTrue);
      expect(response1.result?['exitCode'], equals(0));
      expect(response2.isSuccess, isFalse);
    });
  });
}
