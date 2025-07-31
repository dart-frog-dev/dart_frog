/// {@template dart_frog_daemon_exception}
/// An exception thrown when the daemon fails.
/// {@endtemplate}
abstract class DartFrogDaemonException implements Exception {
  /// {@macro dart_frog_daemon_exception}
  const DartFrogDaemonException(this.message);

  /// The exception message.
  final String message;
}

/// {@template dart_frog_daemon_message_exception}
/// An exception thrown when the daemon fails to parse a message.
/// {@endtemplate}
class DartFrogDaemonMessageException extends DartFrogDaemonException {
  /// {@macro dart_frog_daemon_message_exception}
  const DartFrogDaemonMessageException(super.message);
}

/// {@template dart_frog_daemon_malformed_message_exception}
/// An exception thrown when the daemon fails to parse the
/// structure of a message.
/// {@endtemplate}
class DartFrogDaemonMalformedMessageException
    extends DartFrogDaemonMessageException {
  /// {@macro dart_frog_daemon_malformed_message_exception}
  const DartFrogDaemonMalformedMessageException(String message)
    : super('Malformed message, $message');
}

/// {@template dart_frog_daemon_missing_parameter_exception}
/// An exception thrown when the daemon reports a missing parameter of a
/// message.
/// {@endtemplate}
class DartFrogDaemonMissingParameterException
    extends DartFrogDaemonMessageException {
  /// {@macro dart_frog_daemon_malformed_message_exception}
  const DartFrogDaemonMissingParameterException(String message)
    : super('Missing parameter, $message');
}
