import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'helpers/helpers.dart';

/// Objectives:
///
/// * Generate a new Dart Frog project via `dart_frog create`
/// * Run the dev server via `dart_frog dev`
/// * Ensure the server responds accordingly for built-in endpoints
void main() {
  group('dart_frog dev', () {
    const projectName = 'example';
    final tempDirectory = Directory.systemTemp.createTempSync();

    late Process process;

    setUpAll(() async {
      await dartFrogCreate(projectName: projectName, directory: tempDirectory);
      process = await dartFrogDev(
        directory: Directory(path.join(tempDirectory.path, projectName)),
      );
    });

    tearDownAll(() async {
      await killDartFrogServer(process.pid).ignoreErrors();
      tempDirectory.delete(recursive: true).ignore();
    });

    testServer('GET / returns 200 with greeting', (host) async {
      final response = await http.get(Uri.parse(host));
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.body, equals('Welcome to Dart Frog!'));
      expect(response.headers, contains('date'));
      expect(
        response.headers,
        containsPair('content-type', 'text/plain; charset=utf-8'),
      );
    });

    testServer('GET /not_here returns 404', (host) async {
      final response = await http.get(Uri.parse('$host/not_here'));
      expect(response.statusCode, HttpStatus.notFound);
      expect(response.body, 'Route not found');
    });
  });

  group('dart_frog dev when ran multiple times', () {
    const projectName1 = 'example1';
    const projectName2 = 'example2';

    final tempDirectory = Directory.systemTemp.createTempSync();

    setUpAll(() async {
      await dartFrogCreate(projectName: projectName1, directory: tempDirectory);
      await dartFrogCreate(projectName: projectName2, directory: tempDirectory);
    });

    tearDownAll(() {
      tempDirectory.delete(recursive: true).ignore();
    });

    test('running two different dart_frog dev command will fail '
        'when different dart vm port is not set', () async {
      final process1 = await dartFrogDev(
        directory: Directory(path.join(tempDirectory.path, projectName1)),
      );
      addTearDown(() async {
        await killDartFrogServer(process1.pid).ignoreErrors();
      });

      try {
        final process2 = await dartFrogDev(
          directory: Directory(path.join(tempDirectory.path, projectName2)),
          exitOnError: false,
        );
        addTearDown(() async {
          await killDartFrogServer(process2.pid).ignoreErrors();
        });

        fail('exception not thrown');
      } catch (e) {
        expect(e.toString(), contains('Could not start the VM service:'));

        expect(
          e.toString(),
          contains(
            'DartDevelopmentServiceException: Failed to create server socket',
          ),
        );

        expect(e.toString(), contains('127.0.0.1:8181'));
      }
    });

    test(
      'runs two different dart_frog dev servers without any issues',
      () async {
        final process1 = await dartFrogDev(
          directory: Directory(path.join(tempDirectory.path, projectName1)),
        );

        addTearDown(() async {});

        final process2Future = dartFrogDev(
          directory: Directory(path.join(tempDirectory.path, projectName2)),
          exitOnError: false,
          args: ['--dart-vm-service-port', '9191'],
        );

        expect(process2Future, completes);

        addTearDown(() async {
          final process2 = await process2Future;

          await killDartFrogServer(process1.pid).ignoreErrors();
          await killDartFrogServer(process2.pid).ignoreErrors();
        });
      },
    );
  });
}

extension<T> on Future<T> {
  Future<void> ignoreErrors() async {
    try {
      await this;
    } catch (_) {}
  }
}
