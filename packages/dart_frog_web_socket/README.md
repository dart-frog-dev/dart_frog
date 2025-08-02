[<img src="https://raw.githubusercontent.com/dart-frog-dev/dart_frog/main/assets/dart_frog.png" align="left" height="63.5px" />](https://dart-frog.dev)

### Dart Frog Web Socket

<br clear="left"/>

[![discord][discord_badge]][discord_link]
[![dart][dart_badge]][dart_link]

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

WebSocket support for [Dart Frog][dart_frog_link].

[Originally developed][credits_link] by [Very Good Ventures][very_good_ventures_link] 🦄

Learn more about it on the [official docs][docs_link].

## Quick Start 🚀

Use `webSocketHandler` to manage `WebSocket` connections in a Dart Frog route handler.

```dart
// routes/ws.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';

Handler get onRequest {
  return webSocketHandler(
    (channel, protocol) {
      // A new connection was established.
      print('connected');
      // Subscribe to the stream of messages from the client.
      channel.stream.listen(
        (message) {
          // Handle incoming messages.
          print('received: $message');
          // Send outgoing messages to the connected client.
          channel.sink.add('pong');
        },
        // The connection was terminated.
        onDone: () => print('disconnected'),
      );
    },
  );
}
```

Connect a client to the remote WebSocket endpoint.

```dart
// main.dart
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  // Connect to the remote WebSocket endpoint.
  final uri = Uri.parse('ws://localhost:8080/ws');
  final channel = WebSocketChannel.connect(uri);

  // Listen to incoming messages from the server.
  channel.stream.listen(print);

  // Send messages to the server.
  channel.sink.add('ping');
}
```

[ci_badge]: https://github.com/dart-frog-dev/dart_frog/actions/workflows/dart_frog_web_socket.yaml/badge.svg?branch=main
[ci_link]: https://github.com/dart-frog-dev/dart_frog/actions/workflows/dart_frog_web_socket.yaml
[coverage_badge]: https://raw.githubusercontent.com/dart-frog-dev/dart_frog/main/packages/dart_frog_web_socket/coverage_badge.svg
[credits_link]: https://github.com/dart-frog-dev/dart_frog/blob/main/CREDITS.md#acknowledgments
[dart_badge]: https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=5BB4F0&color=1E2833
[dart_link]: https://dart.dev
[dart_frog_link]: https://github.com/dart-frog-dev/dart_frog
[discord_badge]: https://img.shields.io/discord/1394707782271238184?style=for-the-badge&logo=discord&color=1C2A2E&logoColor=1DF9D2
[discord_link]: https://discord.gg/dart-frog
[docs_link]: https://dart-frog.dev/advanced/web-sockets
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/dart-frog-dev/dart_frog/main/assets/dart_frog_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/dart-frog-dev/dart_frog/main/assets/dart_frog_logo_white.png#gh-dark-mode-only
[pub_badge]: https://img.shields.io/pub/v/dart_frog_web_socket.svg
[pub_link]: https://pub.dartlang.org/packages/dart_frog_web_socket
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_ventures_link]: https://verygood.ventures
