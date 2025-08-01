import 'package:dart_frog/dart_frog.dart';

// Missing parameter
// expect_lint: dart_frog_route
Response onRequest(RequestContext context) {
  return Response();
}
