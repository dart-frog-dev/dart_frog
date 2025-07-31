import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:mocktail/mocktail.dart';

import 'package:test/test.dart';

class _TestDomain extends DomainBase {
  _TestDomain(super.daemon, {super.getId});

  @override
  Future<void> dispose() async {}

  @override
  String get domainName => 'test';
}

class _MockDaemonServer extends Mock implements DaemonServer {}

void main() {
  group('$DomainBase', () {
    Future<DaemonResponse> myHandler(DaemonRequest request) async {
      return DaemonResponse.success(
        id: request.id,
        result: {'foo': 'bar', if (request.params != null) ...request.params!},
      );
    }

    test('routes requests to handlers', () async {
      final domain = _TestDomain(_MockDaemonServer())
        ..addHandler('myHandler', myHandler);
      final response = await domain.handleRequest(
        const DaemonRequest(
          id: '1',
          method: 'myHandler',
          domain: 'test',
          params: {'baz': 'qux'},
        ),
      );

      expect(
        response,
        equals(
          const DaemonResponse.success(
            id: '1',
            result: {'foo': 'bar', 'baz': 'qux'},
          ),
        ),
      );
    });

    test('handles invalid requests', () async {
      final domain = _TestDomain(_MockDaemonServer())
        ..addHandler('myHandler', myHandler);
      final response = await domain.handleRequest(
        const DaemonRequest(id: '1', method: 'invalidHandler', domain: 'test'),
      );

      expect(
        response,
        equals(
          const DaemonResponse.error(
            id: '1',
            error: {'message': 'Method not found: invalidHandler'},
          ),
        ),
      );
    });

    test('handle malformed requests', () async {
      Future<DaemonResponse> myHandler(DaemonRequest request) async {
        throw const DartFrogDaemonMalformedMessageException('oopsie');
      }

      final domain = _TestDomain(_MockDaemonServer())
        ..addHandler('myHandler', myHandler);

      final response = await domain.handleRequest(
        const DaemonRequest(id: '1', method: 'myHandler', domain: 'test'),
      );

      expect(
        response,
        equals(
          const DaemonResponse.error(
            id: '1',
            error: {'message': 'Malformed message, oopsie'},
          ),
        ),
      );
    });

    test('getId returns as passed', () async {
      final domain = _TestDomain(_MockDaemonServer(), getId: () => 'id');

      expect(domain.getId(), equals('id'));
    });
  });
}
