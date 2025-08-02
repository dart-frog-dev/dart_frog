// ignoring for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:bearer_authentication/hash_extension.dart';
import 'package:bearer_authentication/session_repository.dart';
import 'package:test/test.dart';

void main() {
  group('SessionRepository', () {
    test('creates a session for the given user', () async {
      final now = DateTime(2021);
      final repository = SessionRepository(now: () => now);
      final session = await repository.createSession('1');

      expect(session, isNotNull);
      expect(session.token, equals('1_2021-01-01T00:00:00.000'.hashValue));
      expect(session.userId, equals('1'));
      expect(session.expiryDate, equals(now.add(const Duration(days: 1))));
      expect(session.createdAt, equals(now));
    });

    group('usessionFromToken', () {
      test('returns null if no session is found', () async {
        sessionDb = {};
        final repository = SessionRepository();
        final session = await repository.sessionFromToken('token');

        expect(session, isNull);
      });

      test('returns the session when it exists and has not expired', () async {
        final now = DateTime(2021);
        final repository = SessionRepository(now: () => now);

        sessionDb = {
          'a': Session(
            token: 'a',
            userId: '1',
            createdAt: now,
            expiryDate: now.add(const Duration(days: 1)),
          ),
        };

        final session = await repository.sessionFromToken('a');
        expect(session, isNotNull);
        expect(
          session,
          equals(
            Session(
              token: 'a',
              userId: '1',
              createdAt: now,
              expiryDate: now.add(const Duration(days: 1)),
            ),
          ),
        );
      });

      test('returns null when the session exists but is expired', () async {
        final now = DateTime(2021);
        final repository = SessionRepository(now: () => now);

        sessionDb = {
          'a': Session(
            token: 'a',
            userId: '1',
            createdAt: now.subtract(const Duration(days: 2)),
            expiryDate: now.subtract(const Duration(days: 1)),
          ),
        };

        final session = await repository.sessionFromToken('a');
        expect(session, isNull);
      });
    });
  });
}
