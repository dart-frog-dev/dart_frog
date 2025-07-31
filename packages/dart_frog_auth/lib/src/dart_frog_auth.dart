import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

extension on Map<String, String> {
  String? authorization(String type) {
    final value = this['Authorization']?.split(' ');

    if (value != null && value.length == 2 && value.first == type) {
      return value.last;
    }

    return null;
  }

  String? bearer() => authorization('Bearer');
  String? basic() => authorization('Basic');
  Map<String, String>? cookies() {
    final cookieString = this['Cookie'];
    if (cookieString == null) return null;

    final cookiesEntries = cookieString.split('; ').map((cookie) {
      final [key, value] = cookie.split('=');
      return MapEntry(key, value);
    });

    return Map.fromEntries(cookiesEntries);
  }
}

/// Function definition for the predicate function used by Dart Frog Auth
/// middleware to determine if the request should be authenticated or not.
typedef Applies = Future<bool> Function(RequestContext context);

Future<bool> _defaultApplies(RequestContext context) async => true;

/// Authentication that uses the `Authorization` header with the `Basic` scheme.
///
/// `Basic` scheme expects the header to be in the format:
/// ```markdown
/// Authorization: Basic <token>
/// ```
///
/// Token should be a base64 encoded string of the format:
/// ```markdown
/// <username>:<password>
/// ```
///
/// In order to use this middleware, you must provide a function that will
/// return a user object from the username, password and request context.
///
/// If the given function returns null for the given username and password,
/// the middleware will return a `401 Unauthorized` response.
///
/// By default, this middleware will apply to all routes. You can change this
/// behavior by providing a function that returns a boolean value based on the
/// [RequestContext]. If the function returns false, the middleware will not
/// apply to the route and the call will have authentication validation.
Middleware basicAuthentication<T extends Object>({
  @Deprecated(
    'Deprecated in favor of authenticator. '
    'This will be removed in future versions',
  )
  Future<T?> Function(
    String username,
    String password,
  )? userFromCredentials,
  Future<T?> Function(
    RequestContext context,
    String username,
    String password,
  )? authenticator,
  Applies applies = _defaultApplies,
  Handler? unauthenticatedResponse,
}) {
  assert(
    userFromCredentials != null || authenticator != null,
    'You must provide either a userFromCredentials or a '
    'authenticator function',
  );
  return (handler) => (context) async {
        if (!await applies(context)) {
          return handler(context);
        }

        Future<T?> call(String username, String password) async {
          if (userFromCredentials != null) {
            return userFromCredentials(username, password);
          } else {
            return authenticator!(context, username, password);
          }
        }

        final authorization = context.request.headers.basic();
        if (authorization != null) {
          final [username, password] =
              String.fromCharCodes(base64Decode(authorization)).split(':');

          final user = await call(username, password);
          if (user != null) {
            return handler(context.provide(() => user));
          }
        }

        return unauthenticatedResponse?.call(context) ??
            Response(statusCode: HttpStatus.unauthorized);
      };
}

/// Authentication that uses the `Authorization` header with the `Bearer`
/// scheme.
///
/// `Bearer` scheme expects the header to be in the format:
/// ```markdown
/// Authorization: Bearer <token>
/// ```
///
/// The token format is up to the user. Usually it will be an encrypted token.
///
/// In order to use this middleware, you must provide a function that will
/// return a user object from the received token and request context.
///
/// If the given function returns null for the given username and password,
/// the middleware will return a `401 Unauthorized` response.
///
/// By default, this middleware will apply to all routes. You can change this
/// behavior by providing a function that returns a boolean value based on the
/// [RequestContext]. If the function returns false, the middleware will not
/// apply to the route and the call will have no authentication validation.
Middleware bearerAuthentication<T extends Object>({
  @Deprecated(
    'Deprecated in favor of authenticator. '
    'This will be removed in future versions',
  )
  Future<T?> Function(String token)? userFromToken,
  Future<T?> Function(RequestContext context, String token)? authenticator,
  Applies applies = _defaultApplies,
  Handler? unauthenticatedResponse,
}) {
  assert(
    userFromToken != null || authenticator != null,
    'You must provide either a userFromToken or a '
    'authenticator function',
  );

  return (handler) => (context) async {
        if (!await applies(context)) {
          return handler(context);
        }

        Future<T?> call(String token) async {
          if (userFromToken != null) {
            return userFromToken(token);
          } else {
            return authenticator!(context, token);
          }
        }

        final authorization = context.request.headers.bearer();
        if (authorization != null) {
          final user = await call(authorization);
          if (user != null) {
            return handler(context.provide(() => user));
          }
        }

        return unauthenticatedResponse?.call(context) ??
            Response(statusCode: HttpStatus.unauthorized);
      };
}

/// Authentication that uses the `Cookie` header.
///
/// Cookie authentication expects cookies to be sent in the format:
/// ```markdown
/// Cookie: key1=value1; key2=value2;
/// ```
///
/// This is typically done in web applications where the cookie is set with the
/// `Set-Cookie` header, then sent with every request by a browser.
///
/// The cookie format and contents are up to the user. Typically they will
/// identify a logged in session.
///
/// In order to use this middleware, you must provide a function that will
/// return a user object from the cookies and request context.
///
/// If the given function returns null for the given cookies,
/// the middleware will return a `401 Unauthorized` response.
///
/// By default, this middleware will apply to all routes. You can change this
/// behavior by providing a function that returns a boolean value based on the
/// [RequestContext]. If the function returns false, the middleware will not
/// apply to the route and the call will have no authentication validation.
Middleware cookieAuthentication<T extends Object>({
  required Future<T?> Function(
    RequestContext context,
    Map<String, String> cookies,
  ) authenticator,
  Applies applies = _defaultApplies,
  Handler? unauthenticatedResponse,
}) {
  return (handler) => (context) async {
        if (!await applies(context)) {
          return handler(context);
        }

        final cookies = context.request.headers.cookies();

        if (cookies != null) {
          final user = await authenticator(context, cookies);
          if (user != null) {
            return handler(context.provide(() => user));
          }
        }

        return unauthenticatedResponse?.call(context) ??
            Response(statusCode: HttpStatus.unauthorized);
      };
}
