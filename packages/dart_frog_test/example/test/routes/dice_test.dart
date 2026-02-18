import 'dart:math';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/dice.dart' as route;

class _MockRandom extends Mock implements Random {}

void main() {
  test(
    'responds with a 200 and the rolled number.',
    () async {
      final random = _MockRandom();
      when(() => random.nextInt(6)).thenReturn(2);

      final testContext = TestRequestContext(
        path: '/dice',
        method: HttpMethod.post,
      )..provide<Random>(random);

      final response = route.onRequest(testContext.context);
      expect(response, isOk);
      expectJsonBody(response, {'value': 3});
    },
  );

  test(
    'only allows post method',
    () async {
      // ignoring for testing.
      // ignore: experimental_member_use
      await expectNotAllowedMethods(
        route.onRequest,
        contextBuilder: (method) => TestRequestContext(
          path: '/dice',
          method: method,
        ),
        allowedMethods: [HttpMethod.post],
      );
    },
  );
}
