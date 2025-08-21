import 'dart:async';
import 'dart:io';

import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:dart_frog_cli/src/dev_server_runner/dev_server_runner.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockDaemonServer extends Mock implements DaemonServer {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockDevServerRunner extends Mock implements DevServerRunner {}

class _FakeDaemonEvent extends Fake implements DaemonEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDaemonEvent());
  });

  group('$DevServerDomain', () {
    late DaemonServer daemonServer;
    late MasonGenerator generator;
    late DevServerRunner runner;
    late DevServerDomain domain;
    late Completer<ExitCode> completer;

    setUp(() {
      daemonServer = _MockDaemonServer();
      generator = _MockMasonGenerator();
      runner = _MockDevServerRunner();
      domain = DevServerDomain(
        daemonServer,
        getId: () => 'id',
        generator: (_) async => generator,
        devServerRunnerConstructor: ({
          required logger,
          required port,
          required address,
          required devServerBundleGenerator,
          required dartVmServicePort,
          required workingDirectory,
          void Function()? onHotReloadEnabled,
        }) {
          return runner;
        },
      );
      completer = Completer();
      when(() => runner.start()).thenAnswer((_) async {});
      when(() => runner.exitCode).thenAnswer((_) async => completer.future);
      when(() => runner.isCompleted).thenReturn(true);
    });

    test('can be instantiated', () {
      expect(DevServerDomain(daemonServer), isNotNull);
    });

    group('start', () {
      test('starts application', () async {
        late Logger passedLogger;
        late String passedPort;
        late InternetAddress? passedAddress;
        late MasonGenerator passedDevServerBundleGenerator;
        late String passedDartVmServicePort;
        late Directory passedWorkingDirectory;
        final domain = DevServerDomain(
          daemonServer,
          getId: () => 'id',
          generator: (_) async => generator,
          devServerRunnerConstructor: ({
            required logger,
            required port,
            required address,
            required devServerBundleGenerator,
            required dartVmServicePort,
            required workingDirectory,
            void Function()? onHotReloadEnabled,
          }) {
            passedLogger = logger;
            passedPort = port;
            passedAddress = address;
            passedDevServerBundleGenerator = devServerBundleGenerator;
            passedDartVmServicePort = dartVmServicePort;
            passedWorkingDirectory = workingDirectory;
            return runner;
          },
        );

        expect(
          await domain.handleRequest(
            const DaemonRequest(
              id: '12',
              domain: 'dev_server',
              method: 'start',
              params: {
                'workingDirectory': '/',
                'port': 3000,
                'hostname': '192.168.1.2',
                'dartVmServicePort': 3001,
              },
            ),
          ),
          equals(
            const DaemonResponse.success(
              id: '12',
              result: {'applicationId': 'id'},
            ),
          ),
        );

        expect(passedLogger, isA<DaemonLogger>());
        expect(passedPort, equals('3000'));
        expect(passedAddress, InternetAddress.tryParse('192.168.1.2'));
        expect(passedDevServerBundleGenerator, same(generator));
        expect(passedDartVmServicePort, equals('3001'));
        expect(passedWorkingDirectory.path, equals('/'));

        verify(
          () => daemonServer.sendEvent(
            const DaemonEvent(
              domain: 'dev_server',
              event: 'applicationStarting',
              params: {'applicationId': 'id', 'requestId': '12'},
            ),
          ),
        ).called(1);
      });

      group('missing parameters', () {
        test('workingDirectory', () async {
          expect(
            await domain.handleRequest(
              const DaemonRequest(
                id: '12',
                domain: 'dev_server',
                method: 'start',
                params: {'port': 3000, 'dartVmServicePort': 3001},
              ),
            ),
            equals(
              const DaemonResponse.error(
                id: '12',
                error: {
                  'message': 'Missing parameter, workingDirectory not found',
                },
              ),
            ),
          );
        });

        test('port', () async {
          expect(
            await domain.handleRequest(
              const DaemonRequest(
                id: '12',
                domain: 'dev_server',
                method: 'start',
                params: {
                  'workingDirectory': '/',
                  'dartVmServicePort': 3001,
                },
              ),
            ),
            equals(
              const DaemonResponse.error(
                id: '12',
                error: {
                  'message': 'Missing parameter, port not found',
                },
              ),
            ),
          );
        });

        test('dartVmServicePort', () async {
          expect(
            await domain.handleRequest(
              const DaemonRequest(
                id: '12',
                domain: 'dev_server',
                method: 'start',
                params: {
                  'workingDirectory': '/',
                  'port': 3000,
                },
              ),
            ),
            equals(
              const DaemonResponse.error(
                id: '12',
                error: {
                  'message': 'Missing parameter, dartVmServicePort not found',
                },
              ),
            ),
          );
        });
      });

      group('malformed messages', () {
        test('workingDirectory', () async {
          expect(
            await domain.handleRequest(
              const DaemonRequest(
                id: '12',
                domain: 'dev_server',
                method: 'start',
                params: {'workingDirectory': 123},
              ),
            ),
            equals(
              const DaemonResponse.error(
                id: '12',
                error: {
                  'message': 'Malformed message, invalid workingDirectory',
                },
              ),
            ),
          );
        });

        test('port', () async {
          expect(
            await domain.handleRequest(
              const DaemonRequest(
                id: '12',
                domain: 'dev_server',
                method: 'start',
                params: {
                  'workingDirectory': '/',
                  'port': 'lol',
                },
              ),
            ),
            equals(
              const DaemonResponse.error(
                id: '12',
                error: {'message': 'Malformed message, invalid port'},
              ),
            ),
          );
        });

        test('dartVmServicePort', () async {
          expect(
            await domain.handleRequest(
              const DaemonRequest(
                id: '12',
                domain: 'dev_server',
                method: 'start',
                params: {
                  'workingDirectory': '/',
                  'port': 3000,
                  'dartVmServicePort': 'lol',
                },
              ),
            ),
            equals(
              const DaemonResponse.error(
                id: '12',
                error: {
                  'message': 'Malformed message, invalid dartVmServicePort',
                },
              ),
            ),
          );
        });

        test('hostname', () async {
          expect(
            await domain.handleRequest(
              const DaemonRequest(
                id: '12',
                domain: 'dev_server',
                method: 'start',
                params: {
                  'workingDirectory': '/',
                  'port': 4040,
                  'dartVmServicePort': 4041,
                  'hostname': 'lol',
                },
              ),
            ),
            equals(
              const DaemonResponse.error(
                id: '12',
                error: {
                  'message': 'Malformed message, invalid hostname "lol": '
                      'must be a valid IPv4 or IPv6 address.',
                },
              ),
            ),
          );
        });
      });

      test('on dev server throw', () async {
        when(() => runner.start()).thenThrow('error');
        expect(
          await domain.handleRequest(
            const DaemonRequest(
              id: '12',
              domain: 'dev_server',
              method: 'start',
              params: {
                'workingDirectory': '/',
                'port': 3000,
                'dartVmServicePort': 3001,
              },
            ),
          ),
          equals(
            const DaemonResponse.error(
              id: '12',
              error: {'applicationId': 'id', 'message': 'error'},
            ),
          ),
        );
      });
    });

    group('reload', () {
      setUp(() async {
        when(() => runner.reload()).thenAnswer((_) async {});
        await domain.handleRequest(
          const DaemonRequest(
            id: '12',
            domain: 'dev_server',
            method: 'start',
            params: {
              'workingDirectory': '/',
              'port': 3000,
              'dartVmServicePort': 3001,
            },
          ),
        );
      });

      test('should reload', () async {
        expect(
          await domain.handleRequest(
            const DaemonRequest(
              id: '12',
              domain: 'dev_server',
              method: 'reload',
              params: {'applicationId': 'id'},
            ),
          ),
          equals(
            const DaemonResponse.success(
              id: '12',
              result: {'applicationId': 'id'},
            ),
          ),
        );

        verify(() => runner.reload()).called(1);
      });

      group('malformed messages', () {
        test('applicationId', () async {
          expect(
            await domain.handleRequest(
              const DaemonRequest(
                id: '12',
                domain: 'dev_server',
                method: 'reload',
                params: {'applicationId': 123},
              ),
            ),
            equals(
              const DaemonResponse.error(
                id: '12',
                error: {
                  'message': 'Malformed message, invalid applicationId',
                },
              ),
            ),
          );
        });

        group('missing parameters', () {
          test('applicationId', () async {
            expect(
              await domain.handleRequest(
                const DaemonRequest(
                  id: '12',
                  domain: 'dev_server',
                  method: 'reload',
                  params: {},
                ),
              ),
              equals(
                const DaemonResponse.error(
                  id: '12',
                  error: {
                    'message': 'Missing parameter, applicationId not found',
                  },
                ),
              ),
            );
          });
        });

        test('application not found', () async {
          expect(
            await domain.handleRequest(
              const DaemonRequest(
                id: '12',
                domain: 'dev_server',
                method: 'reload',
                params: {'applicationId': 'different-id'},
              ),
            ),
            equals(
              const DaemonResponse.error(
                id: '12',
                error: {
                  'applicationId': 'different-id',
                  'message': 'Application not found',
                },
              ),
            ),
          );
        });
      });

      test('on dev server throw', () async {
        when(() => runner.reload()).thenThrow('error');

        expect(
          await domain.handleRequest(
            const DaemonRequest(
              id: '12',
              domain: 'dev_server',
              method: 'reload',
              params: {'applicationId': 'id'},
            ),
          ),
          equals(
            const DaemonResponse.error(
              id: '12',
              error: {'applicationId': 'id', 'message': 'error'},
            ),
          ),
        );
      });
    });

    group('stop', () {
      setUp(() async {
        when(() => runner.stop()).thenAnswer((_) async {});

        await domain.handleRequest(
          const DaemonRequest(
            id: '12',
            domain: 'dev_server',
            method: 'start',
            params: {
              'workingDirectory': '/',
              'port': 3000,
              'dartVmServicePort': 3001,
            },
          ),
        );
      });

      test('should stop', () async {
        completer.complete(ExitCode.success);
        expect(
          await domain.handleRequest(
            const DaemonRequest(
              id: '12',
              domain: 'dev_server',
              method: 'stop',
              params: {'applicationId': 'id'},
            ),
          ),
          equals(
            const DaemonResponse.success(
              id: '12',
              result: {
                'applicationId': 'id',
                'exitCode': 0,
              },
            ),
          ),
        );

        verify(() => runner.stop()).called(1);
      });

      group('malformed messages', () {
        test('applicationId', () async {
          expect(
            await domain.handleRequest(
              const DaemonRequest(
                id: '12',
                domain: 'dev_server',
                method: 'stop',
                params: {'applicationId': 123},
              ),
            ),
            equals(
              const DaemonResponse.error(
                id: '12',
                error: {
                  'message': 'Malformed message, invalid applicationId',
                },
              ),
            ),
          );
        });

        group('missing parameters', () {
          test('applicationId', () async {
            expect(
              await domain.handleRequest(
                const DaemonRequest(
                  id: '12',
                  domain: 'dev_server',
                  method: 'stop',
                  params: {},
                ),
              ),
              equals(
                const DaemonResponse.error(
                  id: '12',
                  error: {
                    'message': 'Missing parameter, applicationId not found',
                  },
                ),
              ),
            );
          });
        });

        test('application not found', () async {
          expect(
            await domain.handleRequest(
              const DaemonRequest(
                id: '12',
                domain: 'dev_server',
                method: 'stop',
                params: {'applicationId': 'different-id'},
              ),
            ),
            equals(
              const DaemonResponse.error(
                id: '12',
                error: {
                  'applicationId': 'different-id',
                  'message': 'Application not found',
                },
              ),
            ),
          );
        });
      });

      test('on dev server throw', () async {
        when(() => runner.stop()).thenThrow('error');

        expect(
          await domain.handleRequest(
            const DaemonRequest(
              id: '12',
              domain: 'dev_server',
              method: 'stop',
              params: {'applicationId': 'id'},
            ),
          ),
          equals(
            const DaemonResponse.error(
              id: '12',
              error: {
                'applicationId': 'id',
                'message': 'error',
                'finished': true,
              },
            ),
          ),
        );
      });

      test('on non completed dev server throw', () async {
        when(() => runner.stop()).thenThrow('error');
        when(() => runner.isCompleted).thenReturn(false);

        expect(
          await domain.handleRequest(
            const DaemonRequest(
              id: '12',
              domain: 'dev_server',
              method: 'stop',
              params: {'applicationId': 'id'},
            ),
          ),
          equals(
            const DaemonResponse.error(
              id: '12',
              error: {
                'applicationId': 'id',
                'message': 'error',
                'finished': false,
              },
            ),
          ),
        );
      });
    });

    test('dispose stops all runners', () async {
      final runner1 = _MockDevServerRunner();
      when(runner1.stop).thenAnswer((_) async {});
      final runner2 = _MockDevServerRunner();
      when(runner2.stop).thenAnswer((_) async {});

      var calls = 0;

      final domain = DevServerDomain(
        daemonServer,
        generator: (_) async => generator,
        devServerRunnerConstructor: ({
          required logger,
          required port,
          required address,
          required devServerBundleGenerator,
          required dartVmServicePort,
          required workingDirectory,
          void Function()? onHotReloadEnabled,
        }) {
          final runner = calls == 0 ? runner1 : runner2;
          calls++;
          return runner;
        },
      );

      await domain.handleRequest(
        const DaemonRequest(
          id: '12',
          domain: 'dev_server',
          method: 'start',
          params: {
            'workingDirectory': '/',
            'port': 3000,
            'dartVmServicePort': 3001,
          },
        ),
      );

      await domain.handleRequest(
        const DaemonRequest(
          id: '13',
          domain: 'dev_server',
          method: 'start',
          params: {
            'workingDirectory': '/',
            'port': 6000,
            'dartVmServicePort': 6001,
          },
        ),
      );

      await domain.dispose();
      verify(runner1.stop).called(1);
      verify(runner2.stop).called(1);
    });
  });
}
