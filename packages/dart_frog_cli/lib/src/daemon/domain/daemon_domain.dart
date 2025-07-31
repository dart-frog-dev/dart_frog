import 'dart:io';

import 'package:dart_frog_cli/src/daemon/daemon.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';

/// {@template daemon_domain}
/// The daemon domain.
///
/// This should include all the meta-related methods.
/// {@endtemplate}
class DaemonDomain extends DomainBase {
  /// {@macro daemon_domain}
  DaemonDomain(super.daemon, {@visibleForTesting int? processId}) {
    addHandler('requestVersion', _requestVersion);
    addHandler('kill', _kill);

    daemon.sendEvent(
      DaemonEvent(
        domain: domainName,
        event: 'ready',
        params: {'version': daemon.version, 'processId': processId ?? pid},
      ),
    );
  }

  /// The name of this domain.
  static const String name = 'daemon';

  @override
  String get domainName => name;

  /// Requests the version of the daemon.
  Future<DaemonResponse> _requestVersion(DaemonRequest request) async {
    return DaemonResponse.success(
      id: request.id,
      result: {'version': daemon.version},
    );
  }

  /// Kills the daemon.
  Future<DaemonResponse> _kill(DaemonRequest request) async {
    daemon.kill(ExitCode.success).ignore();
    return DaemonResponse.success(
      id: request.id,
      result: const {'message': 'Hogarth. You stay, I go. No following.'},
    );
  }

  @override
  Future<void> dispose() async {}
}
