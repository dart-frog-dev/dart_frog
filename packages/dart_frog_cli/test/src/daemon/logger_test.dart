import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:test/test.dart';

void main() {
  Matcher unsupportedErrorWithMessage(String name) {
    return isA<UnsupportedError>().having(
      (p) => p.message,
      'message',
      'Unsupported daemon logger property: $name',
    );
  }

  final daemonEvents = <DaemonEvent>[];

  void sendEvent(DaemonEvent event) => daemonEvents.add(event);

  tearDown(daemonEvents.clear);

  group('$DaemonLogger', () {
    final logger = DaemonLogger(
      domain: 'test',
      params: {'meta-information1': true},
      sendEvent: sendEvent,
      idGenerator: () => 'id',
    );

    test('can be instantiated', () {
      expect(
        DaemonLogger(
          domain: 'test',
          params: {},
          sendEvent: (event) {},
          idGenerator: () => 'id',
        ),
        isNotNull,
      );
    });

    test('alert', () {
      logger.alert('alert');

      expect(daemonEvents.length, equals(1));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'loggerAlert',
          params: {'meta-information1': true, 'message': 'alert'},
        ),
      );
    });

    test('chooseAny', () {
      expect(
        () => logger.chooseAny('choose any of this', choices: ['oi', 'ai']),
        throwsA(unsupportedErrorWithMessage('chooseAny')),
      );
    });

    test('chooseOne', () {
      expect(
        () => logger.chooseOne('choose one of this', choices: ['oi', 'ai']),
        throwsA(unsupportedErrorWithMessage('chooseOne')),
      );
    });

    test('confirm', () {
      expect(
        () => logger.confirm('confirm this'),
        throwsA(unsupportedErrorWithMessage('confirm')),
      );
    });

    test('delayed/flush', () {
      logger
        ..delayed('delayed1')
        ..delayed('delayed2')
        ..flush();

      expect(daemonEvents.length, 2);
      expect(
        daemonEvents.first,
        const DaemonEvent(
          domain: 'test',
          event: 'loggerInfo',
          params: {'meta-information1': true, 'message': 'delayed1'},
        ),
      );

      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'loggerInfo',
          params: {'meta-information1': true, 'message': 'delayed2'},
        ),
      );
    });

    test('detail', () {
      logger.detail('detail');

      expect(daemonEvents.length, equals(1));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'loggerDetail',
          params: {'meta-information1': true, 'message': 'detail'},
        ),
      );
    });

    test('err', () {
      logger.err('err');

      expect(daemonEvents.length, equals(1));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'loggerError',
          params: {'meta-information1': true, 'message': 'err'},
        ),
      );
    });

    test('info', () {
      logger.info('info');

      expect(daemonEvents.length, equals(1));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'loggerInfo',
          params: {'meta-information1': true, 'message': 'info'},
        ),
      );
    });

    test('prompt', () {
      expect(
        () => logger.prompt('prompt this'),
        throwsA(unsupportedErrorWithMessage('prompt')),
      );
    });

    test('promptAny', () {
      expect(
        () => logger.promptAny('prompt anything'),
        throwsA(unsupportedErrorWithMessage('promptAny')),
      );
    });

    test('success', () {
      logger.success('success');

      expect(daemonEvents.length, equals(1));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'loggerSuccess',
          params: {'meta-information1': true, 'message': 'success'},
        ),
      );
    });

    test('warn', () {
      logger.warn('warn');

      expect(daemonEvents.length, equals(1));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'loggerWarning',
          params: {'meta-information1': true, 'message': 'warn'},
        ),
      );
    });

    test('write', () {
      logger.write('write');

      expect(daemonEvents.length, equals(1));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'loggerWrite',
          params: {'meta-information1': true, 'message': 'write'},
        ),
      );
    });

    test('theme', () => expect(logger.theme, isNotNull));

    test('progressOptions', () => expect(logger.progressOptions, isNotNull));

    test('progress', () {
      final progress = logger.progress('progress this');
      expect(
        progress,
        isA<DaemonProgress>()
            .having((e) => e.message, 'progress', equals('progress this'))
            .having((e) => e.sendEvent, 'progress sendEvent', same(sendEvent))
            .having(
              (e) => e.params,
              'progress params',
              equals({'meta-information1': true}),
            )
            .having((e) => e.domain, 'progress domain', equals('test'))
            .having((e) => e.id, 'progress id', equals('id')),
      );
    });
  });

  group('DaemonProgress', () {
    late DaemonProgress progress;
    setUp(() {
      progress = DaemonProgress(
        domain: 'test',
        params: {'meta-information1': true},
        sendEvent: sendEvent,
        id: 'id',
        message: 'initial message',
      );
    });

    test('sends initial message upon construction', () {
      expect(daemonEvents.length, equals(1));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'progressStart',
          params: {
            'meta-information1': true,
            'progressMessage': 'initial message',
            'progressId': 'id',
          },
        ),
      );
    });

    test('update', () {
      expect(daemonEvents.length, equals(1));
      progress.update('update message');
      expect(daemonEvents.length, equals(2));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'progressUpdate',
          params: {
            'meta-information1': true,
            'progressMessage': 'update message',
            'progressId': 'id',
          },
        ),
      );
    });

    test('complete', () {
      expect(daemonEvents.length, equals(1));
      progress.complete();
      expect(daemonEvents.length, equals(2));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'progressComplete',
          params: {
            'meta-information1': true,
            'progressMessage': 'initial message',
            'progressId': 'id',
          },
        ),
      );
      progress.complete('complete message');
      expect(daemonEvents.length, equals(3));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'progressComplete',
          params: {
            'meta-information1': true,
            'progressMessage': 'complete message',
            'progressId': 'id',
          },
        ),
      );
    });

    test('cancel', () {
      expect(daemonEvents.length, equals(1));
      progress.cancel();
      expect(daemonEvents.length, equals(2));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'progressCancel',
          params: {
            'meta-information1': true,
            'progressMessage': 'initial message',
            'progressId': 'id',
          },
        ),
      );
    });

    test('fail', () {
      expect(daemonEvents.length, equals(1));
      progress.fail();
      expect(daemonEvents.length, equals(2));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'progressFail',
          params: {
            'meta-information1': true,
            'progressMessage': 'initial message',
            'progressId': 'id',
          },
        ),
      );
      progress.fail('fail message');
      expect(daemonEvents.length, equals(3));
      expect(
        daemonEvents.last,
        const DaemonEvent(
          domain: 'test',
          event: 'progressFail',
          params: {
            'meta-information1': true,
            'progressMessage': 'fail message',
            'progressId': 'id',
          },
        ),
      );
    });
  });
}
