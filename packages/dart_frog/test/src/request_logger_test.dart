import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('requestLogger', () {
    var gotLog = false;

    // ignoring to align with shelf logger
    // ignore: avoid_positional_boolean_parameters
    void logger(String msg, bool isError) {
      expect(gotLog, isFalse);
      gotLog = true;
      expect(isError, isFalse);
      expect(msg, contains('GET'));
      expect(msg, contains('[200]'));
    }

    test('proxies to logRequests', () async {
      final handler = const Pipeline()
          .addMiddleware(requestLogger(logger: logger))
          .addHandler((_) => Response());
      final request = Request.get(Uri.parse('http://localhost/'));
      final context = _MockRequestContext();
      when(() => context.request).thenReturn(request);
      await handler(context);

      expect(gotLog, isTrue);
    });
  });
}
