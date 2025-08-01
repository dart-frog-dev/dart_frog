import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_frog_lint/src/dart_frog_entrypoint.dart';
import 'package:test/test.dart';

void main() {
  group('dart_frog_entrypoint', () {
    test(
        'Emits warning if the second parameter a class named InternetAddress '
        'but not from dart:io', () async {
      final file = File(
        'test/src/dart_frog_entrypoint_sources/incorrect_ip.dart',
      ).absolute;

      final result = await resolveFile2(path: file.path);
      result as ResolvedUnitResult;

      final error = await const DartFrogEntrypoint()
          .testRun(result)
          .then((e) => e.single);

      expect(error.message, 'Main files should define a valid "run" function.');
      expect(error.offset, 89);
      expect(error.length, 103);
    });

    test(
        'Emits warning if the second parameter is class from dart:io but not '
        'named InternetAddress', () async {
      final file = File(
        'test/src/dart_frog_entrypoint_sources/incorrect_sdk_ip.dart',
      ).absolute;

      final result = await resolveFile2(path: file.path);
      result as ResolvedUnitResult;

      final error = await const DartFrogEntrypoint()
          .testRun(result)
          .then((e) => e.single);

      expect(error.message, 'Main files should define a valid "run" function.');
      expect(error.offset, 63);
      expect(error.length, 98);
    });

    test('Emits warning if the result returns a non-future HttpServer',
        () async {
      final file = File(
        'test/src/dart_frog_entrypoint_sources/non_future_result.dart',
      ).absolute;

      final result = await resolveFile2(path: file.path);
      result as ResolvedUnitResult;

      final error = await const DartFrogEntrypoint()
          .testRun(result)
          .then((e) => e.single);

      expect(error.message, 'Main files should define a valid "run" function.');
      expect(error.offset, 63);
      expect(error.length, 95);
    });

    test('Emits warning if the result returns a non Future<HttpServer> result',
        () async {
      final file = File(
        'test/src/dart_frog_entrypoint_sources/non_http_server_result.dart',
      ).absolute;

      final result = await resolveFile2(path: file.path);
      result as ResolvedUnitResult;

      final error = await const DartFrogEntrypoint()
          .testRun(result)
          .then((e) => e.single);

      expect(error.message, 'Main files should define a valid "run" function.');
      expect(error.offset, 84);
      expect(error.length, 103);
    });

    test(
        'Emits warning if the result returns a non Future<class from dart:io>,'
        ' but the class is not a HttpServer', () async {
      final file = File(
        'test/src/dart_frog_entrypoint_sources/non_server_io_result.dart',
      ).absolute;

      final result = await resolveFile2(path: file.path);
      result as ResolvedUnitResult;

      final error = await const DartFrogEntrypoint()
          .testRun(result)
          .then((e) => e.single);

      expect(error.message, 'Main files should define a valid "run" function.');
      expect(error.offset, 63);
      expect(error.length, 108);
    });
  });
}
