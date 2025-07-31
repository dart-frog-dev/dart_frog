import 'dart:io';

import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

/// Objectives:
///
/// * Generate a new Dart Frog project via `dart_frog create`
/// * Start the daemon
/// * verify daemon is ready
/// * send invalid messages
/// * request daemon.* methods
void main() {
  const projectName = 'example';
  final tempDirectory = Directory.systemTemp.createTempSync();

  late Process daemonProcess;

  late final DaemonStdioHelper daemonStdio;

  setUpAll(() async {
    await dartFrogCreate(projectName: projectName, directory: tempDirectory);
    daemonProcess = await dartFrogDaemonStart();

    daemonStdio = DaemonStdioHelper(daemonProcess);
    addTearDown(() => daemonStdio.dispose());
  });

  group('daemon domain', () {
    test('daemon is ready', () async {
      final readyEvent = await daemonStdio.awaitForDaemonEvent('daemon.ready');
      expect(readyEvent.params?.keys, containsAll(['version', 'processId']));
    });

    group('daemon responds to invalid messages', () {
      test('daemon responds to an invalid message', () async {
        await daemonStdio.sendStringMessage('ooga boga');
        final protocolError = await daemonStdio.awaitForDaemonEvent(
          'daemon.protocolError',
        );
        expect(protocolError.params?['message'], equals('Not a valid JSON'));
      });

      test('daemon process responds to invalid json', () async {
        await daemonStdio.sendStringMessage('{}');
        final protocolError = await daemonStdio.awaitForDaemonEvent(
          'daemon.protocolError',
        );
        expect(
          protocolError.params?['message'],
          equals('Message should be placed within a JSON list'),
        );
      });

      test('daemon process responds to unknown message type', () async {
        await daemonStdio.sendStringMessage('[{}]');
        final protocolError = await daemonStdio.awaitForDaemonEvent(
          'daemon.protocolError',
        );
        expect(
          protocolError.params?['message'],
          equals('Unknown message type: {}'),
        );
      });

      test('daemon process responds to unknown message type', () async {
        await daemonStdio.sendStringMessage('[{"id": 0, "method": "foo.bar"}]');
        final protocolError = await daemonStdio.awaitForDaemonEvent(
          'daemon.protocolError',
        );
        expect(
          protocolError.params?['message'],
          equals('Malformed message, Invalid id: 0'),
        );
      });

      test('daemon process responds to unknown domain', () async {
        final response = await daemonStdio.sendDaemonRequest(
          const DaemonRequest(
            id: '1',
            domain: 'wrongdomain',
            method: 'unkownmethod',
          ),
          timeout: const Duration(seconds: 5),
        );

        expect(
          response.error,
          equals({'message': 'Invalid domain: wrongdomain'}),
        );
      });

      test('daemon process responds to unknown method', () async {
        final response = await daemonStdio.sendDaemonRequest(
          const DaemonRequest(
            id: '1',
            domain: 'daemon',
            method: 'unkownmethod',
          ),
          timeout: const Duration(seconds: 5),
        );

        expect(
          response.error,
          equals({'message': 'Method not found: unkownmethod'}),
        );
      });
    });

    test('daemon.requestVersion', () async {
      final response = await daemonStdio.sendDaemonRequest(
        const DaemonRequest(
          id: '1',
          domain: 'daemon',
          method: 'requestVersion',
        ),
      );

      expect(response.result, equals({'version': '0.0.1'}));
    });

    test('daemon.kill', () async {
      final response = await daemonStdio.sendDaemonRequest(
        const DaemonRequest(id: '1', domain: 'daemon', method: 'kill'),
      );

      expect(
        response.result,
        equals({'message': 'Hogarth. You stay, I go. No following.'}),
      );

      final exitCode = await daemonProcess.exitCode;
      expect(exitCode, equals(0));
    });
  });
}
