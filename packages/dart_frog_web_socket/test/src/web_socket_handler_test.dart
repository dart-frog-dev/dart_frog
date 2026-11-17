import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/src/web_socket_handler.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

Map<String, String> get _handshakeHeaders {
  return {
    'Upgrade': 'websocket',
    'Connection': 'Upgrade',
    'Sec-WebSocket-Key': 'x3JJHMbDL1EzLkh9GBhXDw==',
    'Sec-WebSocket-Version': '13',
  };
}

void main() {
  group('webSocketHandler', () {
    test('can communicate with a WebSocket client', () async {
      final server = await serve(
        webSocketHandler((channel, protocol) {
          channel.sink.add('ack');
          channel.stream.first.then((request) {
            expect(request, equals('ping'));
            channel.sink.add('pong');
            channel.sink.close();
          });
        }),
        'localhost',
        0,
      );

      try {
        final webSocket = await WebSocket.connect(
          'ws://localhost:${server.port}',
        );

        var n = 0;
        await webSocket.listen((message) {
          if (n == 0) {
            expect(message, equals('ack'));
            webSocket.add('ping');
          } else if (n == 1) {
            expect(message, equals('pong'));
            webSocket.close();
            server.close();
          } else {
            fail('Only expected two messages.');
          }
          n++;
        }).asFuture<void>();
      } finally {
        await server.close();
      }
    });

    group('protocols', () {
      test('are negotiated', () async {
        final server = await serve(
          webSocketHandler(
            (channel, protocol) {
              expect(protocol, equals('two'));
              channel.sink.close();
            },
            protocols: ['three', 'two', 'other'],
          ),
          'localhost',
          0,
        );

        try {
          final webSocket = await WebSocket.connect(
            'ws://localhost:${server.port}',
            protocols: ['one', 'two', 'three'],
          );
          expect(webSocket.protocol, equals('two'));
          await webSocket.close();
        } finally {
          await server.close();
        }
      });

      test('protocol header is null when protocols are not specified',
          () async {
        final server = await serve(
          webSocketHandler((channel, protocol) {
            channel.sink.close();
          }),
          'localhost',
          0,
        );

        try {
          final webSocket = await WebSocket.connect(
            'ws://localhost:${server.port}',
            protocols: ['one', 'two', 'three'],
          );
          expect(webSocket.protocol, isNull);
          await webSocket.close();
        } finally {
          await server.close();
        }
      });
    });

    group('allowedOrigins', () {
      late HttpServer server;
      late Uri url;

      setUp(() async {
        server = await serve(
          webSocketHandler(
            (channel, protocol) {
              channel.sink.close();
            },
            allowedOrigins: ['vgv.dev', 'FlUtTeR.DeV'],
          ),
          'localhost',
          0,
        );
        url = Uri.http('localhost:${server.port}');
      });

      tearDown(() => server.close());

      test('allows access with an allowed origin', () {
        final headers = _handshakeHeaders;
        headers['Origin'] = 'vgv.dev';
        expect(http.get(url, headers: headers), hasStatus(101));
      });

      test('forbids access with a non-allowed origin', () {
        final headers = _handshakeHeaders;
        headers['Origin'] = 'google.com';
        expect(http.get(url, headers: headers), hasStatus(403));
      });

      test('allows access with no origin', () {
        expect(http.get(url, headers: _handshakeHeaders), hasStatus(101));
      });

      test('ignores the case of the client origin', () {
        final headers = _handshakeHeaders;
        headers['Origin'] = 'VgV.DeV';
        expect(http.get(url, headers: headers), hasStatus(101));
      });

      test('ignores the case of the server origin', () {
        final headers = _handshakeHeaders;
        headers['Origin'] = 'flutter.dev';
        expect(http.get(url, headers: headers), hasStatus(101));
      });
    });

    group('HTTP errors', () {
      late HttpServer server;
      late Uri url;

      setUp(() async {
        server = await serve(
          webSocketHandler((_, __) {
            fail('should not create a WebSocket');
          }),
          'localhost',
          0,
        );
        url = Uri.http('localhost:${server.port}');
      });

      tearDown(() => server.close());

      test('returns 404 for non-GET request', () {
        expect(http.delete(url, headers: _handshakeHeaders), hasStatus(404));
      });

      test('returns 404 for non-Upgrade requests', () {
        final headers = _handshakeHeaders..remove('Connection');
        expect(http.get(url, headers: headers), hasStatus(404));
      });

      test('returns 404 for non-websocket upgrade requests', () {
        final headers = _handshakeHeaders;
        headers['Upgrade'] = 'fblthp';
        expect(http.get(url, headers: headers), hasStatus(404));
      });

      test('returns 400 for a missing Sec-WebSocket-Version', () {
        final headers = _handshakeHeaders..remove('Sec-WebSocket-Version');
        expect(http.get(url, headers: headers), hasStatus(400));
      });

      test('returns 404 for an unknown Sec-WebSocket-Version', () {
        final headers = _handshakeHeaders;
        headers['Sec-WebSocket-Version'] = '15';
        expect(http.get(url, headers: headers), hasStatus(404));
      });

      test('returns 400 for a missing Sec-WebSocket-Key', () {
        final headers = _handshakeHeaders..remove('Sec-WebSocket-Key');
        expect(http.get(url, headers: headers), hasStatus(400));
      });
    });
  });
}

Matcher hasStatus(int status) {
  return completion(
    predicate((http.Response response) {
      expect(response.statusCode, equals(status));
      return true;
    }),
  );
}
