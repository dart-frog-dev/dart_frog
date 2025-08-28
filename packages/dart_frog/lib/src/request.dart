part of '_internal.dart';

/// {@template unsupported_http_method_exception}
/// Exception thrown when an unsupported HTTP method is used.
/// {@endtemplate}
class UnsupportedHttpMethodException implements Exception {
  /// {@macro unsupported_http_method_exception}
  const UnsupportedHttpMethodException(this.method);

  /// The unsupported http method.
  final String method;

  @override
  String toString() => '''
Unsupported HTTP method: $method. 
The following methods are supported:
${HttpMethod.values.map((m) => m.value.toUpperCase()).join(', ')}.''';
}

/// {@template request}
/// An HTTP request.
/// {@endtemplate}
class Request {
  /// {@macro request}
  Request(
    String method,
    Uri uri, {
    Map<String, Object>? headers,
    Object? body,
    Encoding? encoding,
  }) : this._(
          shelf.Request(
            method,
            uri,
            headers: headers,
            body: body,
            encoding: encoding,
          ),
        );

  /// An HTTP DELETE request.
  Request.delete(
    Uri uri, {
    Map<String, Object>? headers,
    Object? body,
    Encoding? encoding,
  }) : this(
          HttpMethod.delete.value,
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        );

  /// An HTTP GET request.
  Request.get(
    Uri uri, {
    Map<String, Object>? headers,
    Object? body,
    Encoding? encoding,
  }) : this(
          HttpMethod.get.value,
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        );

  /// An HTTP PATCH request.
  Request.patch(
    Uri uri, {
    Map<String, Object>? headers,
    Object? body,
    Encoding? encoding,
  }) : this(
          HttpMethod.patch.value,
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        );

  /// An HTTP POST request.
  Request.post(
    Uri uri, {
    Map<String, Object>? headers,
    Object? body,
    Encoding? encoding,
  }) : this(
          HttpMethod.post.value,
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        );

  /// An HTTP PUT request.
  Request.put(
    Uri uri, {
    Map<String, Object>? headers,
    Object? body,
    Encoding? encoding,
  }) : this(
          HttpMethod.put.value,
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        );

  Request._(this._request);

  final shelf.Request _request;

  /// Connection information for the associated HTTP request.
  HttpConnectionInfo get connectionInfo {
    return _request.context['shelf.io.connection_info']! as HttpConnectionInfo;
  }

  /// The requested url relative to the current handler path.
  Uri get url => _request.url;

  /// The original requested [Uri].
  Uri get uri => _request.requestedUri;

  /// The HTTP headers with case-insensitive keys.
  /// The returned map is unmodifiable.
  Map<String, String> get headers => _request.headers;

  /// The [HttpMethod] associated with the request.
  HttpMethod get method {
    return HttpMethod.values.firstWhere(
      (m) => m.value == _request.method,
      orElse: () => throw UnsupportedHttpMethodException(_request.method),
    );
  }

  /// Returns the url parameters captured by the [Router].
  /// Returns an empty map if no parameters are captured.
  ///
  /// The returned map is unmodifiable.
  Map<String, String> get params => _request.params;

  /// Returns a [Stream] representing the body.
  Stream<List<int>> bytes() => _request.read();

  /// Returns a [Future] containing the body as a [String].
  Future<String> body() async {
    final bodyFromContext = _bodyFutureExpando[_request];
    if (bodyFromContext != null) return bodyFromContext;

    final completer = Completer<String>();
    try {
      _bodyFutureExpando[_request] = completer.future;
      completer.complete(await _request.readAsString());
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }

    return completer.future;
  }

  /// Returns a [Future] containing the form data as a [Map].
  Future<FormData> formData() {
    return parseFormData(headers: headers, body: body, bytes: bytes);
  }

  /// Returns a [Future] containing the body text parsed as a json object.
  /// This object could be anything that can be represented by json
  /// e.g. a map, a list, a string, a number, a bool...
  Future<dynamic> json() async => jsonDecode(await body());

  /// Creates a new [Request] by copying existing values and applying specified
  /// changes.
  Request copyWith({
    Map<String, Object?>? headers,
    String? path,
    Object? body,
  }) {
    return Request._(_request.change(headers: headers, path: path, body: body));
  }
}

final _bodyFutureExpando = Expando<Future<String>>('dart_frog.request.body');
