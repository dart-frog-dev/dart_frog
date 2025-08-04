import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:test/test.dart';

/// Starts the dart_frog daemon in the given directory.
Future<Process> dartFrogDaemonStart() {
  return Process.start('dart_frog', ['daemon'], runInShell: true);
}

/// Converts a raw message from the daemon stdout
/// into a [DaemonMessage].
DaemonMessage _sdtOutLineToMessage(String rawMessage) {
  final jsonList = jsonDecode(rawMessage) as List<dynamic>;
  final jsonMap = jsonList.first as Map<String, dynamic>;
  return DaemonMessage.fromJson(jsonMap);
}

/// A helper class to interact with the daemon process
/// via its stdin and stdout.
class DaemonStdioHelper {
  DaemonStdioHelper(this.daemonProcess) {
    subscription = daemonProcess.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleStdoutLine);
  }

  final Process daemonProcess;

  late StreamSubscription<String> subscription;

  var _pastMessagesCache = <String>[];

  List<Matcher> messageMatchers = [];
  List<Completer<String>> messageCompleters = [];

  void _handleStdoutLine(String line) {
    final messageMatchers = this.messageMatchers;

    stdout.writeln('::debug:: <- $line');

    for (final (index, messageMatcher) in messageMatchers.indexed) {
      if (messageMatcher.matches(line, {})) {
        messageCompleters[index].complete(line);
        _pastMessagesCache.clear();
        return;
      }
    }

    _pastMessagesCache.add(line);
  }

  void _clean(Matcher messageMatcher, Completer<String>? completer) {
    messageMatchers.remove(messageMatcher);
    messageCompleters.remove(completer);
  }

  /// Awaits for a daemon event with the given [methodKey].
  Future<DaemonEvent> awaitForDaemonEvent(
    String methodKey, {
    Duration timeout = _defaultTimeout,
    Matcher? withParamsThat,
  }) async {
    var wrappedMatcher = isA<DaemonEvent>().having(
      (e) => '${e.domain}.${e.event}',
      'is $methodKey',
      methodKey,
    );

    if (withParamsThat != null) {
      wrappedMatcher = wrappedMatcher.having(
        (e) => e.params,
        'params',
        withParamsThat,
      );
    }

    final result = await awaitForDaemonMessage(
      wrappedMatcher,
      timeout: timeout,
    );

    return result as DaemonEvent;
  }

  /// Awaits for a daemon message that matches the given [messageMatcher].
  Future<DaemonMessage> awaitForDaemonMessage(
    Matcher messageMatcher, {
    Duration timeout = _defaultTimeout,
  }) async {
    final wrappedMatcher = _MatchMessageToStdoutLine(messageMatcher);

    final resultString = await awaitForStringMessage(
      wrappedMatcher,
      timeout: timeout,
    );

    return _sdtOutLineToMessage(resultString);
  }

  /// Awaits for a string message that matches the given [messageMatcher].
  Future<String> awaitForStringMessage(
    Matcher messageMatcher, {
    Duration timeout = _defaultTimeout,
  }) async {
    messageMatchers.add(messageMatcher);

    // Check if there is already a matching message in the cache.
    final existingItem = _pastMessagesCache.indexed.where((pair) {
      return messageMatcher.matches(pair.$2, {});
    }).firstOrNull;

    if (existingItem case (final int itemIndex, final String itemValue)) {
      // If there is a matching message in the cache,
      // remove all the previous messages from the cache and
      // return the matching message.
      _pastMessagesCache = _pastMessagesCache.skip(itemIndex + 1).toList();
      _clean(messageMatcher, null);
      return itemValue;
    }

    // If there is no matching message in the cache,
    // create a completer and wait for the message to be received
    // or for the timeout to expire.

    final messageCompleter = Completer<String>();

    messageCompleters.add(messageCompleter);
    final result = await Future.any(<Future<String?>>[
      messageCompleter.future,
      Future<String?>.delayed(timeout),
    ]);

    _clean(messageMatcher, messageCompleter);

    if (result == null) {
      throw TimeoutException('Timed out waiting for message', timeout);
    }

    return result;
  }

  /// Sends a string message to the daemon via its stdin.
  Future<void> sendStringMessage(String message) async {
    stdout.writeln('::debug:: -> $message');
    daemonProcess.stdin.writeln(message);
    await daemonProcess.stdin.flush();
  }

  /// Sends a daemon request to the daemon via its stdin.
  /// Returns the response or throws a
  /// [TimeoutException] if the timeout expires.
  Future<DaemonResponse> sendDaemonRequest(
    DaemonRequest request, {
    Duration timeout = _defaultTimeout,
  }) async {
    final json = jsonEncode(request.toJson());

    await sendStringMessage('[$json]');

    final wrappedMatcher = isA<DaemonResponse>().having(
      (e) => e.id,
      'id is ${request.id}',
      request.id,
    );

    final responseMessage = await awaitForDaemonMessage(
      wrappedMatcher,
      timeout: timeout,
    );

    return responseMessage as DaemonResponse;
  }

  /// Sends two daemon requests to the daemon via its stdin.
  ///
  /// Returns a tuple with the responses or throws a
  /// [TimeoutException] if the timeout expires.
  Future<(DaemonResponse, DaemonResponse)> sendStaggeredDaemonRequest(
    (DaemonRequest, DaemonRequest) requests, {
    Duration timeout = _defaultTimeout,
  }) async {
    final request1 = requests.$1;
    final request2 = requests.$2;

    final json1 = jsonEncode(request1.toJson());
    final json2 = jsonEncode(request2.toJson());

    stdout.writeln('::debug:: -> [$json1]');
    daemonProcess.stdin.writeln('[$json1]');
    stdout.writeln('::debug:: -> [$json2]');
    daemonProcess.stdin.writeln('[$json2]');
    await daemonProcess.stdin.flush();

    final wrappedMatcher1 = isA<DaemonResponse>().having(
      (e) => e.id,
      'id is ${request1.id}',
      request1.id,
    );

    final wrappedMatcher2 = isA<DaemonResponse>().having(
      (e) => e.id,
      'id is ${request2.id}',
      request2.id,
    );

    final responseMessage1 = awaitForDaemonMessage(
      wrappedMatcher1,
      timeout: timeout,
    );

    final responseMessage2 = awaitForDaemonMessage(
      wrappedMatcher2,
      timeout: timeout,
    );

    final result = await Future.wait([responseMessage1, responseMessage2]);

    return (result.first as DaemonResponse, result.last as DaemonResponse);
  }

  void dispose() {
    subscription.cancel();
  }

  static const _defaultTimeout = Duration(seconds: 10);
}

/// A matcher that matches a [DaemonMessage] to a daemon stdout line.
class _MatchMessageToStdoutLine extends CustomMatcher {
  _MatchMessageToStdoutLine(Matcher matcher)
    : super('Message to stdout line', 'message', matcher);

  @override
  Object? featureValueOf(dynamic actual) {
    if (actual is String) {
      return _sdtOutLineToMessage(actual);
    }
    return actual;
  }
}
