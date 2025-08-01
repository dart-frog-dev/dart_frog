import 'package:dart_frog/dart_frog.dart';

// Incorrect parameter type
// expect_lint: dart_frog_route
Response onRequest(RequestContext context, int userId2) {
  return Response();
}
