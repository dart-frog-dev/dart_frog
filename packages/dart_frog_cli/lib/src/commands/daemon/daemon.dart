import 'package:dart_frog_cli/src/command.dart';
import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:meta/meta.dart';

/// Type definition for a function which creates a [DaemonServer].
typedef DaemonBuilder = DaemonServer Function();

/// {@template daemon_command}
/// `dart_frog daemon` command which starts the Dart Frog daemon.
/// {@endtemplate}
class DaemonCommand extends DartFrogCommand {
  /// {@macro daemon_command}
  DaemonCommand({super.logger, DaemonBuilder? daemonBuilder})
    : _daemonBuilder = daemonBuilder ?? DaemonServer.new;

  final DaemonBuilder _daemonBuilder;

  @override
  String get description => 'Start the Dart Frog daemon';

  @override
  String get name => 'daemon';

  /// The [DaemonServer] instance used by this command.
  ///
  /// Visible for testing purposes only.
  @visibleForTesting
  late final DaemonServer daemon = _daemonBuilder();

  @override
  Future<int> run() async => (await daemon.exitCode).code;
}
