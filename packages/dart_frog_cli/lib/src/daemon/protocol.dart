import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:equatable/equatable.dart';

/// {@template daemon_message}
/// Defines a message that is sent or received by the daemon.
///
/// There are three types of messages:
/// - [DaemonRequest]s are method invocation requests.
/// - [DaemonResponse]s are responses to [DaemonRequest]s.
/// - [DaemonEvent]s are events that are sent spontaneously.
///
/// The daemon protocol is asynchronous, so [DaemonRequest]s and
/// [DaemonResponse]s are identified by an id. The daemon will make
/// sure that the responses will have the same id as the request.
///
/// Therefore the uniqueness of the id should be guaranteed by the
/// client.
///
/// There should be only one response for a request.
/// {@endtemplate}
sealed class DaemonMessage extends Equatable {
  /// {@macro daemon_message}
  const DaemonMessage();

  /// Creates a [DaemonMessage] from a [rawMessage] json.
  ///
  /// Throws a [DartFrogDaemonMessageException] if the message
  /// is invalid, malformed or unknown.
  factory DaemonMessage.fromJson(Map<String, dynamic> rawMessage) {
    switch (rawMessage) {
      case {'id': _, 'method': _}:
        return DaemonRequest.fromJson(rawMessage);
      case {'id': _, 'result': _} || {'id': _, 'error': _}:
        return DaemonResponse.fromJson(rawMessage);
      case {'event': _}:
        return DaemonEvent.fromJson(rawMessage);
      default:
        throw DartFrogDaemonMessageException(
          'Unknown message type: $rawMessage',
        );
    }
  }

  /// Converts this [DaemonMessage] to a `<String, dynamic>` map.
  Map<String, dynamic> toJson();
}

/// {@template daemon_request}
/// A request to invoke a method.
/// {@endtemplate}
class DaemonRequest extends DaemonMessage {
  /// {@macro daemon_request}
  const DaemonRequest({
    required this.id,
    required this.domain,
    required this.method,
    this.params,
  });

  /// Creates a [DaemonRequest] from a [rawMessage] json.
  factory DaemonRequest.fromJson(Map<String, dynamic> rawMessage) {
    final id = rawMessage['id'];
    if (id is! String) {
      throw DartFrogDaemonMalformedMessageException('Invalid id: $id');
    }

    final rawMethod = rawMessage['method'];
    if (rawMethod is! String) {
      throw DartFrogDaemonMalformedMessageException(
        'Invalid method name: ${rawMessage['method']}',
      );
    }

    final splitMethod = rawMethod.split('.');
    if (splitMethod.length != 2) {
      throw DartFrogDaemonMalformedMessageException(
        'Invalid method name: ${rawMessage['method']}',
      );
    }

    final [domainName, methodName] = splitMethod;

    final params = rawMessage['params'];
    if (params is! Map<String, dynamic>?) {
      throw DartFrogDaemonMalformedMessageException(
        'Invalid params: ${rawMessage['params']}',
      );
    }

    return DaemonRequest(
      id: id,
      method: methodName,
      domain: domainName,
      params: params,
    );
  }

  /// The id responsible to associate this request with a response.
  final String id;

  /// The method to be invoked.
  final String method;

  /// The parameters to be passed to the method.
  final Map<String, dynamic>? params;

  /// The domain of the method.
  final String domain;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': '$domain.$method',
      if (params != null) 'params': params,
    };
  }

  @override
  List<Object?> get props => [id, method, params, domain];

  ///
  /// Gets a parameter of this request.
  ///
  /// Throws a [DartFrogDaemonMissingParameterException] if the parameter
  /// is not found and type [T] is not nullable.
  ///
  /// Throws a [DartFrogDaemonMalformedMessageException] if the parameter
  /// is not of type [T].
  ///
  /// Required parameters should be typed as not nullable
  ///   `final paramValue = getParam<String>('requiredValue')`.
  ///
  /// Optional parameters should be typed as nullable
  ///  `final paramValue = getParam<String?>('optionalValue')`.
  ///
  T getParam<T>(String name) {
    final params = this.params;

    if (params == null) {
      throw const DartFrogDaemonMalformedMessageException(
        'Missing params object',
      );
    }

    final param = params[name];
    if (param is! T) {
      // Check if param type is optional or not
      if (param == null && null is! T) {
        throw DartFrogDaemonMissingParameterException('$name not found');
      }
      throw DartFrogDaemonMalformedMessageException('invalid $name');
    }

    return param;
  }
}

/// {@template daemon_response}
/// A response to a [DaemonRequest].
/// {@endtemplate}
class DaemonResponse extends DaemonMessage {
  const DaemonResponse._({
    required this.id,
    required this.result,
    required this.error,
  });

  /// Creates a successful [DaemonResponse].
  const DaemonResponse.success({
    required String id,
    required Map<String, dynamic> result,
  }) : this._(id: id, result: result, error: null);

  /// Creates an error [DaemonResponse].
  const DaemonResponse.error({
    required String id,
    required Map<String, dynamic> error,
  }) : this._(id: id, result: null, error: error);

  /// Creates a [DaemonResponse] from a [rawMessage] json.
  factory DaemonResponse.fromJson(Map<String, dynamic> rawMessage) {
    final id = rawMessage['id'];
    if (id is! String) {
      throw DartFrogDaemonMalformedMessageException(
        'Invalid id: ${rawMessage['id']}',
      );
    }

    final result = rawMessage['result'];
    if (result is! Map<String, dynamic>?) {
      throw DartFrogDaemonMalformedMessageException(
        'Invalid result: ${rawMessage['result']}',
      );
    }

    final error = rawMessage['error'];
    if (error is! Map<String, dynamic>?) {
      throw DartFrogDaemonMalformedMessageException(
        'Invalid error: ${rawMessage['error']}',
      );
    }

    return DaemonResponse._(id: id, result: result, error: error);
  }

  /// Whether this response is a success.
  bool get isSuccess => error == null;

  /// The id of the [DaemonRequest] that this response is for.
  final String id;

  /// The result of the method invocation.
  final Map<String, dynamic>? result;

  /// The error that occurred during the method invocation.
  final Map<String, dynamic>? error;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (result != null) 'result': result,
      if (error != null) 'error': error,
    };
  }

  @override
  List<Object?> get props => [id, result, error];
}

/// {@template daemon_event}
/// An event that is sent without necessarily being requested.
/// {@endtemplate}
class DaemonEvent extends DaemonMessage {
  /// {@macro daemon_event}
  const DaemonEvent({required this.domain, required this.event, this.params});

  /// Creates a [DaemonEvent] from a [rawMessage] json.
  factory DaemonEvent.fromJson(Map<String, dynamic> rawMessage) {
    final rawEvent = rawMessage['event'];
    if (rawEvent is! String) {
      throw DartFrogDaemonMalformedMessageException(
        'Invalid event name: ${rawMessage['event']}',
      );
    }

    final splitEvent = rawEvent.split('.');
    if (splitEvent.length != 2) {
      throw DartFrogDaemonMalformedMessageException(
        'Invalid event name: ${rawMessage['event']}',
      );
    }

    final [domainName, eventName] = splitEvent;

    final params = rawMessage['params'];
    if (params is! Map<String, dynamic>?) {
      throw DartFrogDaemonMalformedMessageException(
        'Invalid params: ${rawMessage['params']}',
      );
    }

    return DaemonEvent(event: eventName, domain: domainName, params: params);
  }

  /// The name of the event.
  final String event;

  /// The domain of the event.
  final String domain;

  /// The parameters of the event.
  final Map<String, dynamic>? params;

  @override
  Map<String, dynamic> toJson() {
    return {'event': '$domain.$event', if (params != null) 'params': params};
  }

  @override
  List<Object?> get props => [domain, event, params];
}
