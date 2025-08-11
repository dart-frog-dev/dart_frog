import 'dart:async';
import 'dart:convert';

import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:test/test.dart';

void main() {
  group('$DaemonStdioConnection', () {
    late StreamController<List<int>> stdinStreamController;

    late DaemonStdioConnection connection;

    late List<String> stdoutLines;
    late List<DaemonMessage> receivedMessages;

    setUp(() {
      stdinStreamController = StreamController<List<int>>.broadcast();
      final stdoutStreamController = StreamController<List<int>>.broadcast();

      addTearDown(() {
        stdinStreamController.close();
        stdoutStreamController.close();
      });

      connection = DaemonStdioConnection(
        testStdin: stdinStreamController.stream,
        testStdout: stdoutStreamController.sink,
      );

      stdoutLines = [];
      stdoutStreamController.stream.listen((event) {
        stdoutLines.add(utf8.decode(event));
      });

      receivedMessages = [];
      connection.inputStream.listen((event) {
        receivedMessages.add(event);
      });
    });

    Future<void> sendToConnection(String string) async {
      final bytes = utf8.encode(string);
      stdinStreamController.add(bytes);
      await Future<void>.delayed(Duration.zero);
    }

    tearDown(() {
      connection.dispose();
    });

    test('test handles valid messages', () async {
      final messages = <DaemonMessage>[
        const DaemonRequest(id: '1', method: 'bar', domain: 'foo'),
        const DaemonResponse.success(id: '2', result: {}),
        const DaemonEvent(domain: 'foo', event: 'bar', params: {}),
      ];

      final separators = <String>['\n', '\r\n', '\r'];
      for (final message in messages) {
        await sendToConnection(
          '[${jsonEncode(message.toJson())}]${separators.removeAt(0)}',
        );
      }

      expect(receivedMessages, messages);
      expect(stdoutLines, isEmpty);
    });

    test('handles invalid messages', () async {
      final messages = <String>[
        'not a valid json lol',
        '[]',
        '[{}]',
        '{"method": "daemon.requestVersion", "id": "12"}',
        '[{"id": 1, "method": "foo.bar"}]',
      ];

      for (final message in messages) {
        await sendToConnection('$message\n');
      }

      expect(receivedMessages, isEmpty);
      expect(stdoutLines, <String>[
        '''
[{"event":"daemon.protocolError","params":{"message":"Not a valid JSON"}}]\n''',
        '''
[{"event":"daemon.protocolError","params":{"message":"Invalid message: []"}}]\n''',
        '''
[{"event":"daemon.protocolError","params":{"message":"Unknown message type: {}"}}]\n''',
        '''
[{"event":"daemon.protocolError","params":{"message":"Message should be placed within a JSON list"}}]\n''',
        '''
[{"event":"daemon.protocolError","params":{"message":"Malformed message, Invalid id: 1"}}]\n''',
      ]);
    });

    test('handles unknown error', () async {
      stdinStreamController.addError(Exception('catapimbas'));
      await Future<void>.delayed(Duration.zero);

      expect(receivedMessages, isEmpty);
      expect(stdoutLines, <String>[
        '''
[{"event":"daemon.protocolError","params":{"message":"Unknown error: Exception: catapimbas"}}]\n''',
      ]);
    });

    test('sends messages to stdout', () async {
      final messages = <DaemonMessage>[
        const DaemonRequest(id: '1', method: 'bar', domain: 'foo'),
        const DaemonResponse.success(id: '2', result: {}),
        const DaemonEvent(domain: 'foo', event: 'bar', params: {}),
      ];

      for (final message in messages) {
        connection.outputSink.add(message);
        await Future<void>.delayed(Duration.zero);
      }

      expect(stdoutLines, <String>[
        '[{"id":"1","method":"foo.bar"}]\n',
        '[{"id":"2","result":{}}]\n',
        '[{"event":"foo.bar","params":{}}]\n',
      ]);
    });

    test('dispose frees resources', () async {
      await connection.dispose();
      expect(stdinStreamController.hasListener, isFalse);
    });
  });
}
