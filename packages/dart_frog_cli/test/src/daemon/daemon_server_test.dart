import 'dart:async';

import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';

import 'package:test/test.dart';

class _MockDaemonConnection extends Mock implements DaemonConnection {}

class _TestDomain extends DomainBase {
  _TestDomain(super.daemon) {
    addHandler('something', _something);
  }

  @override
  final String domainName = 'test';

  Future<DaemonResponse> _something(DaemonRequest request) async {
    return DaemonResponse.success(
      id: request.id,
      result: {'foo': 'bar', if (request.params != null) ...request.params!},
    );
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('$DaemonServer', () {
    late DaemonConnection connection;
    late DaemonServer daemonServer;
    late StreamController<DaemonMessage> inputStreamController;
    late StreamController<DaemonMessage> outputStreamController;

    late List<DaemonMessage> outputMessages;

    setUp(() {
      connection = _MockDaemonConnection();

      inputStreamController = StreamController<DaemonMessage>.broadcast();
      outputStreamController = StreamController<DaemonMessage>.broadcast();
      when(
        () => connection.inputStream,
      ).thenAnswer((_) => inputStreamController.stream);
      when(
        () => connection.outputSink,
      ).thenAnswer((_) => outputStreamController.sink);

      daemonServer = DaemonServer(connection: connection);

      outputMessages = <DaemonMessage>[];
      outputStreamController.stream.listen((event) {
        outputMessages.add(event);
      });
    });

    test('can be instantiated', () async {
      expect(DaemonServer(), isNotNull);
    });

    test('version returns daemonVersion', () {
      expect(daemonServer.version, equals(daemonVersion));
    });

    test('domainNames returns the correct domains', () {
      expect(daemonServer.domainNames, [
        'daemon',
        'dev_server',
        'route_configuration',
      ]);
    });

    test('kill exits with given exit code', () async {
      when(() => connection.dispose()).thenAnswer((_) async {});
      await daemonServer.kill(ExitCode.unavailable);
      await expectLater(
        daemonServer.exitCode,
        completion(ExitCode.unavailable),
      );
      verify(() => connection.dispose()).called(1);
    });

    test('sendEvent sends event to connection', () async {
      const event = DaemonEvent(
        domain: 'test',
        event: 'test',
        params: {'param': 2},
      );

      daemonServer.sendEvent(event);

      await Future<void>.delayed(Duration.zero);

      expect(outputMessages, contains(event));
    });

    test('routes requests to correct domain', () async {
      final testDomain = _TestDomain(daemonServer);
      daemonServer.addDomain(testDomain);

      inputStreamController.add(
        const DaemonRequest(
          id: '0',
          method: 'something',
          params: {'boo': 'far'},
          domain: 'test',
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(outputMessages, [
        const DaemonResponse.success(
          id: '0',
          result: {'foo': 'bar', 'boo': 'far'},
        ),
      ]);
    });

    test('handles unknown domains', () async {
      inputStreamController.add(
        const DaemonRequest(
          id: '0',
          method: 'something',
          params: {'boo': 'far'},
          domain: 'test',
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(outputMessages, [
        const DaemonResponse.error(
          id: '0',
          error: {'message': 'Invalid domain: test'},
        ),
      ]);
    });
  });
}
