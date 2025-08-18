import 'dart:async';
import 'dart:io' hide exitCode;

import 'package:dart_frog_cli/src/route_configuration_watcher/route_configuration_watcher.dart';
import 'package:dart_frog_gen/dart_frog_gen.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

class _MockDirectoryWatcher extends Mock implements DirectoryWatcher {}

class _MockLogger extends Mock implements Logger {}

class _MockRouteConfiguration extends Mock implements RouteConfiguration {}

void main() {
  late Logger logger;
  late DirectoryWatcher directoryWatcher;
  late RouteConfigurationWatcher routeConfigurationWatcher;
  late StreamController<WatchEvent> watcherController;

  setUp(() {
    logger = _MockLogger();
    directoryWatcher = _MockDirectoryWatcher();
    watcherController = StreamController<WatchEvent>();
    addTearDown(() {
      watcherController.close();
    });

    when(
      () => directoryWatcher.events,
    ).thenAnswer((_) => watcherController.stream);

    routeConfigurationWatcher = RouteConfigurationWatcher(
      logger: logger,
      workingDirectory: Directory.current,
      onRouteConfigurationChanged: (routeConfiguration) {},
      directoryWatcher: (_) => directoryWatcher,
      routeConfigurationBuilder: (_) => _MockRouteConfiguration(),
    );
  });

  group('$RouteConfigurationWatcher', () {
    test('can be instantiated', () {
      final routeConfigurationWatcher = RouteConfigurationWatcher(
        logger: Logger(),
        workingDirectory: Directory.current,
        onRouteConfigurationChanged: (routeConfiguration) {},
      );
      expect(routeConfigurationWatcher, isNotNull);
    });
  });

  group('start', () {
    test('starts a watcher successfully.', () async {
      await expectLater(routeConfigurationWatcher.start(), completes);

      expect(routeConfigurationWatcher.isWatching, isTrue);
      expect(routeConfigurationWatcher.isRunning, isTrue);
      expect(routeConfigurationWatcher.isCompleted, isFalse);
    });

    test('throws when route config watcher is already running', () async {
      await expectLater(routeConfigurationWatcher.start(), completes);

      await expectLater(
        routeConfigurationWatcher.start(),
        throwsA(
          isA<DartFrogRouteConfigurationWatcherException>().having(
            (e) => e.toString(),
            'message',
            'Cannot start a route config watcher while already running.',
          ),
        ),
      );
    });

    test('throws when route config watcher has been completed', () async {
      await expectLater(routeConfigurationWatcher.start(), completes);
      await routeConfigurationWatcher.stop();

      await expectLater(
        routeConfigurationWatcher.start(),
        throwsA(
          isA<DartFrogRouteConfigurationWatcherException>().having(
            (e) => e.toString(),
            'message',
            'Cannot start a route config watcher after it has been stopped.',
          ),
        ),
      );
    });

    test('generates a new route config on file changes', () async {
      final routeConfiguration = _MockRouteConfiguration();

      var onRouteConfigurationChangedCalls = 0;

      routeConfigurationWatcher = RouteConfigurationWatcher(
        logger: logger,
        workingDirectory: Directory.current,
        onRouteConfigurationChanged: (routeConfiguration) {
          onRouteConfigurationChangedCalls++;
        },
        directoryWatcher: (_) => directoryWatcher,
        routeConfigurationBuilder: (_) => routeConfiguration,
      );

      await routeConfigurationWatcher.start();

      expect(onRouteConfigurationChangedCalls, equals(0));

      watcherController.add(
        WatchEvent(
          ChangeType.MODIFY,
          path.join(Directory.current.path, 'routes', 'index.dart'),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(onRouteConfigurationChangedCalls, equals(1));

      watcherController.add(
        WatchEvent(
          ChangeType.MODIFY,
          path.join(Directory.current.path, 'public', 'index.html'),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(onRouteConfigurationChangedCalls, equals(2));
    });
  });

  group('stop', () {
    test('stops a watcher successfully', () async {
      await expectLater(routeConfigurationWatcher.start(), completes);
      await expectLater(routeConfigurationWatcher.stop(), completes);

      expect(routeConfigurationWatcher.isWatching, isFalse);
      expect(routeConfigurationWatcher.isRunning, isFalse);
      expect(routeConfigurationWatcher.isCompleted, isTrue);
      expect(
        await routeConfigurationWatcher.exitCode,
        equals(ExitCode.success),
      );
    });

    test('stops a stopped watcher', () async {
      await expectLater(routeConfigurationWatcher.start(), completes);
      await expectLater(routeConfigurationWatcher.stop(), completes);
      await expectLater(routeConfigurationWatcher.stop(), completes);

      expect(routeConfigurationWatcher.isCompleted, isTrue);
    });
  });

  group('forceRouteConfigurationRegeneration', () {
    test('generates a route configuration', () async {
      final routeConfiguration = _MockRouteConfiguration();

      routeConfigurationWatcher = RouteConfigurationWatcher(
        logger: logger,
        workingDirectory: Directory.current,
        onRouteConfigurationChanged: (routeConfiguration) {},
        directoryWatcher: (_) => directoryWatcher,
        routeConfigurationBuilder: (_) => routeConfiguration,
      );

      await routeConfigurationWatcher.start();

      final result = routeConfigurationWatcher
          .forceRouteConfigurationRegeneration();

      expect(result, same(routeConfiguration));
    });

    test('returns null when route generation fails', () async {
      routeConfigurationWatcher = RouteConfigurationWatcher(
        logger: logger,
        workingDirectory: Directory.current,
        onRouteConfigurationChanged: (routeConfiguration) {},
        directoryWatcher: (_) => directoryWatcher,
        routeConfigurationBuilder: (_) {
          throw Exception('oops');
        },
      );

      await routeConfigurationWatcher.start();

      final result = routeConfigurationWatcher
          .forceRouteConfigurationRegeneration();

      expect(result, isNull);
    });

    test('returns null when not running', () async {
      final routeConfiguration = _MockRouteConfiguration();

      routeConfigurationWatcher = RouteConfigurationWatcher(
        logger: logger,
        workingDirectory: Directory.current,
        onRouteConfigurationChanged: (routeConfiguration) {},
        directoryWatcher: (_) => directoryWatcher,
        routeConfigurationBuilder: (_) => routeConfiguration,
      );

      await routeConfigurationWatcher.start();
      await routeConfigurationWatcher.stop();

      final result = routeConfigurationWatcher
          .forceRouteConfigurationRegeneration();

      expect(result, isNull);
    });
  });
}
