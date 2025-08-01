import 'package:analyzer/dart/element/type.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// [TypeChecker] for `RequestContext`
const requestContextTypeChecker = TypeChecker.fromName(
  'RequestContext',
  packageName: 'dart_frog',
);

/// [TypeChecker] for `Response`
const _responseTypeChecker = TypeChecker.fromName(
  'Response',
  packageName: 'dart_frog',
);

///  Checks that [type] is `Response | Future<Response>`.
bool isOnRequestResponse(DartType? type) {
  if (type == null) return false;
  if (_responseTypeChecker.isExactlyType(type)) return true;

  if (!type.isDartAsyncFuture) return false;

  type as InterfaceType;
  return _responseTypeChecker.isExactlyType(type.typeArguments.first);
}

/// [TypeChecker] for `Handler`
const _handlerTypeChecker = TypeChecker.fromName(
  'Handler',
  packageName: 'dart_frog',
);

/// Checks that a type is assignable with `Handler`.
///
/// Since `Handler` is a typedef, we need check the alias instead of type matchs
bool isHandler(DartType type) {
  final alias = type.alias;
  if (alias == null) return false;
  return _handlerTypeChecker.isExactly(alias.element);
}

bool _isFromDartSdk(DartType type) => type.element?.library?.isInSdk ?? false;

/// [TypeChecker] for `InternetAddress`
bool isInternetAddress(DartType type) {
  const nameChecker = TypeChecker.fromName('InternetAddress');
  return _isFromDartSdk(type) && nameChecker.isExactlyType(type);
}

/// [TypeChecker] for `HttpServer`
bool isHttpServer(DartType type) {
  const nameChecker = TypeChecker.fromName('HttpServer');
  return _isFromDartSdk(type) && nameChecker.isExactlyType(type);
}
