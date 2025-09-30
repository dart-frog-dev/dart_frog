import 'package:dart_frog_cli/src/command_runner.dart';
import 'package:dart_frog_cli/src/commands/uninstall/uninstall.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('dart_frog uninstall', () {
    late Logger logger;
    late UninstallCommand command;

    setUp(() {
      logger = _MockLogger();
      command = UninstallCommand(logger: logger);
    });

    test('prints a link to the documentation section', () async {
      final result = await command.run();
      final docs = link(
        uri: Uri.parse('https://dart-frog.dev/getting-started#uninstalling'),
      );
      final message =
          'For instructions on how to uninstall $packageName completely, '
          'check out:\n$docs';

      expect(result, equals(ExitCode.success.code));
      verify(() => logger.info(message)).called(1);
    });
  });
}
