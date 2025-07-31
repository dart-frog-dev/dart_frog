import 'dart:async';

import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';

/// The version of the Dart Frog daemon protocol.
///
/// This exists so clients can know if they are compatible with the
/// format and order of the events, the methods,
/// its arguments and return values.
///
/// This does not have to follow the version of the
/// package containing this class.
const daemonVersion = '0.0.1';

/// {@template daemon}
/// The Dart Frog daemon.
///
/// The daemon is a persistent routine that runs, analyzes and manages
/// Dart Frog projects.
/// {@endtemplate}
class DaemonServer {
  /// {@macro daemon}
  DaemonServer({@visibleForTesting DaemonConnection? connection})
    : _connection = connection ?? DaemonStdioConnection() {
    _connection.inputStream.listen(_handleMessage);

    addDomain(DaemonDomain(this));
    addDomain(DevServerDomain(this));
    addDomain(RouteConfigurationDomain(this));
  }

  final Map<String, DomainBase> _domains = {};

  final DaemonConnection _connection;

  final _exitCodeCompleter = Completer<ExitCode>();

  /// A [Future] that completes when the daemon exits.
  Future<ExitCode> get exitCode => _exitCodeCompleter.future;

  /// The names of the domains in the daemon.
  Iterable<String> get domainNames => _domains.keys;

  /// Whether the daemon has exited.
  bool get isCompleted => _exitCodeCompleter.isCompleted;

  /// The version of the Dart Frog daemon protocol.
  String get version => daemonVersion;

  /// Adds a [domain] to the daemon.
  ///
  /// Visible for testing purposes only.
  @visibleForTesting
  @protected
  void addDomain(DomainBase domain) {
    assert(!_domains.containsKey(domain.domainName), 'Domain already exists');
    _domains[domain.domainName] = domain;
  }

  void _handleMessage(DaemonMessage message) {
    if (message is DaemonRequest) {
      _handleRequest(message).ignore();
      return;
    }
    // even though the protocol allows the daemon to receive
    // events and responses, the current implementation
    // only supports requests.
  }

  Future<void> _handleRequest(DaemonRequest request) async {
    final domain = _domains[request.domain];

    if (domain == null) {
      return _sendMessage(
        DaemonResponse.error(
          id: request.id,
          error: {'message': 'Invalid domain: ${request.domain}'},
        ),
      );
    }

    final response = await domain.handleRequest(request);

    _sendMessage(response);
  }

  /// Kills the daemon with the given [exitCode].
  Future<void> kill(ExitCode exitCode) async {
    await Future.wait(_domains.values.map((e) => e.dispose()));
    await _connection.dispose();

    if (_exitCodeCompleter.isCompleted) return;
    _exitCodeCompleter.complete(exitCode);
  }

  void _sendMessage(DaemonMessage message) {
    if (isCompleted) {
      return;
    }
    _connection.outputSink.add(message);
  }

  /// Sends an [event] to the client.
  void sendEvent(DaemonEvent event) {
    _sendMessage(event);
  }
}
