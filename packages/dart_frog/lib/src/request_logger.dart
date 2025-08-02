part of '_internal.dart';

/// Middleware which prints the time of the request, the elapsed time for the
/// inner handlers, the response's status code and the request URI.
///
/// If [logger] is passed, it's called for each request. The `msg` parameter is
/// a formatted string that includes the request time, duration, request method,
/// and requested path. When an exception is thrown, it also includes the
/// exception's string and stack trace; otherwise, it includes the status code.
/// The `isError` parameter indicates whether the message is caused by an error.
///
/// If [logger] is not passed, the message is just passed to [print].
Middleware requestLogger({
  // ignoring to match the shelf.logRequests signature
  // ignore: avoid_positional_boolean_parameters
  void Function(String message, bool isError)? logger,
}) {
  return fromShelfMiddleware(shelf.logRequests(logger: logger));
}
