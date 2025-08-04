import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('fromJson', () {
    test('parses request', () {
      final parsed = DaemonMessage.fromJson(const {
        'id': '1',
        'method': 'foo.bar',
      });
      expect(
        parsed,
        const DaemonRequest(id: '1', method: 'bar', domain: 'foo'),
      );
    });

    test('parses request w/ params', () {
      final parsed = DaemonMessage.fromJson(const {
        'id': '1',
        'method': 'foo.bar',
        'params': {'foo': 'bar'},
      });
      expect(
        parsed,
        const DaemonRequest(
          id: '1',
          method: 'bar',
          domain: 'foo',
          params: {'foo': 'bar'},
        ),
      );
    });

    test('parses response', () {
      final parsed = DaemonMessage.fromJson(const {
        'id': '1',
        'result': {'foo': 'bar'},
      });
      expect(
        parsed,
        const DaemonResponse.success(id: '1', result: {'foo': 'bar'}),
      );
      expect(
        parsed,
        isA<DaemonResponse>().having((e) => e.isSuccess, 'isSuccess', isTrue),
      );

      final parsedError = DaemonMessage.fromJson(const {
        'id': '1',
        'result': null,
        'error': {'foo': 'bar'},
      });
      expect(
        parsedError,
        const DaemonResponse.error(id: '1', error: {'foo': 'bar'}),
      );
      expect(
        parsedError,
        isA<DaemonResponse>().having((e) => e.isSuccess, 'isSuccess', isFalse),
      );
    });

    test('parses event', () {
      final parsed = DaemonMessage.fromJson(const {'event': 'foo.bar'});
      expect(parsed, const DaemonEvent(event: 'bar', domain: 'foo'));
    });

    test('parses event w/ params', () {
      final parsed = DaemonMessage.fromJson(const {
        'event': 'foo.bar',
        'params': {'foo': 'bar'},
      });
      expect(
        parsed,
        const DaemonEvent(event: 'bar', domain: 'foo', params: {'foo': 'bar'}),
      );
    });

    group('malformed request', () {
      test('malformed id', () {
        expect(
          () => DaemonMessage.fromJson(const {'id': 1, 'method': 'foo.bar'}),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });

      test('malformed method', () {
        expect(
          () => DaemonMessage.fromJson(const {'id': '1', 'method': 12}),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });

      test('malformed domain.method', () {
        expect(
          () => DaemonMessage.fromJson(const {'id': '1', 'method': 'foobar'}),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });

      test('malformed params', () {
        expect(
          () => DaemonMessage.fromJson(const {
            'id': '1',
            'method': 'foo.bar',
            'params': 12,
          }),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });
    });

    group('malformed response', () {
      test('malformed id', () {
        expect(
          () => DaemonMessage.fromJson(const {
            'id': 1,
            'result': {'foo': 'bar'},
          }),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });

      test('malformed result', () {
        expect(
          () => DaemonMessage.fromJson(const {'id': '1', 'result': 12}),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });

      test('malformed error', () {
        expect(
          () => DaemonMessage.fromJson(const {
            'id': '1',
            'result': null,
            'error': 12,
          }),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });
    });

    group('malformed event', () {
      test('malformed event', () {
        expect(
          () => DaemonMessage.fromJson(const {'event': 12}),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });

      test('malformed domain.event', () {
        expect(
          () => DaemonMessage.fromJson(const {'event': 'foobar'}),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });

      test('malformed params', () {
        expect(
          () =>
              DaemonMessage.fromJson(const {'event': 'foo.bar', 'params': 12}),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });
    });

    test('throws on unknown message type', () {
      expect(
        () => DaemonMessage.fromJson(const {'foo': 'bar'}),
        throwsA(isA<DartFrogDaemonMessageException>()),
      );
    });
  });

  group('get request param', () {
    group('required', () {
      test('without params', () {
        expect(
          () => const DaemonRequest(
            id: '1',
            domain: 'foo',
            method: 'bar',
          ).getParam<String>('foo'),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });
      test('with empty params', () {
        expect(
          () => const DaemonRequest(
            id: '1',
            domain: 'foo',
            method: 'bar',
            params: <String, String>{},
          ).getParam<String>('foo'),
          throwsA(isA<DartFrogDaemonMissingParameterException>()),
        );
      });
      test('with other params', () {
        expect(
          () => const DaemonRequest(
            id: '1',
            domain: 'foo',
            method: 'bar',
            params: {'bar': 'baz'},
          ).getParam<String>('foo'),
          throwsA(isA<DartFrogDaemonMissingParameterException>()),
        );
      });
      test('with existing param', () {
        expect(
          const DaemonRequest(
            id: '1',
            domain: 'foo',
            method: 'bar',
            params: {'foo': 'bar'},
          ).getParam<String>('foo'),
          'bar',
        );
      });
    });

    group('optional', () {
      test('without params', () {
        expect(
          () => const DaemonRequest(
            id: '1',
            domain: 'foo',
            method: 'bar',
          ).getParam<String?>('foo'),
          throwsA(isA<DartFrogDaemonMalformedMessageException>()),
        );
      });
      test('with empty params', () {
        expect(
          const DaemonRequest(
            id: '1',
            domain: 'foo',
            method: 'bar',
            params: <String, String>{},
          ).getParam<String?>('foo'),
          null,
        );
      });
      test('with other params', () {
        expect(
          const DaemonRequest(
            id: '1',
            domain: 'foo',
            method: 'foo.bar',
            params: {'bar': 'baz'},
          ).getParam<String?>('foo'),
          null,
        );
      });
      test('with existing param', () {
        expect(
          const DaemonRequest(
            id: '1',
            domain: 'foo',
            method: 'bar',
            params: {'foo': 'bar'},
          ).getParam<String?>('foo'),
          'bar',
        );
      });
    });
  });
}
