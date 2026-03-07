import 'package:dart_frog_gen/dart_frog_gen.dart';
import 'package:dart_frog_gen/src/route_specificity.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as path;

class _RouteConflict extends Equatable {
  const _RouteConflict(
    this.originalFilePath,
    this.conflictingFilePath,
    this.conflictingEndpoint,
  );

  final String originalFilePath;
  final String conflictingFilePath;
  final String conflictingEndpoint;

  @override
  List<Object> get props => [
        originalFilePath,
        conflictingFilePath,
        conflictingEndpoint,
      ];
}

/// Type definition for callbacks that report route conflicts.
typedef OnRouteConflict = void Function(
  String originalFilePath,
  String conflictingFilePath,
  String conflictingEndpoint,
);

bool _overlaps(List<String> routeA, List<String> routeB) {
  if (routeA.length != routeB.length) return false;

  for (var i = 0; i < routeA.length; i++) {
    final segmentA = routeA[i];
    final segmentB = routeB[i];

    if (segmentA == segmentB) continue;
    if (segmentA.isDynamic || segmentB.isDynamic) continue;

    return false;
  }

  return true;
}

/// Reports existence of route conflicts on a [RouteConfiguration].
void reportRouteConflicts(
  RouteConfiguration configuration, {
  /// Callback called when any route conflict is found.
  void Function()? onViolationStart,

  /// Callback called for each route conflict found.
  OnRouteConflict? onRouteConflict,

  /// Callback called when any route conflict is found.
  void Function()? onViolationEnd,
}) {
  final directConflicts = configuration.endpoints.entries
      .where((entry) => entry.value.length > 1)
      .map((e) => _RouteConflict(e.value.first.path, e.value.last.path, e.key));

  final indirectConflicts = configuration.endpoints.entries
      .map((entry) {
        final keyParts = entry.key.segments.toList();

        final matches = configuration.endpoints.keys.where((other) {
          if (other == entry.key) return false;

          final otherParts = other.segments.toList();

          if (!_overlaps(keyParts, otherParts)) return false;
          return compareRouteSpecificity(keyParts, otherParts) == 0;
        });

        if (matches.isNotEmpty) {
          final originalFilePath =
              matches.first.endsWith('>') ? matches.first : entry.key;

          final conflictingFilePath =
              entry.key == originalFilePath ? matches.first : entry.key;

          return _RouteConflict(
            originalFilePath,
            conflictingFilePath,
            originalFilePath,
          );
        }

        return null;
      })
      .whereType<_RouteConflict>()
      .toSet();

  final conflictingEndpoints = [...directConflicts, ...indirectConflicts];

  if (conflictingEndpoints.isNotEmpty) {
    onViolationStart?.call();
    for (final conflict in conflictingEndpoints) {
      final originalFilePath = path.normalize(
        path.join('routes', conflict.originalFilePath),
      );
      final conflictingFilePath = path.normalize(
        path.join('routes', conflict.conflictingFilePath),
      );
      onRouteConflict?.call(
        originalFilePath,
        conflictingFilePath,
        conflict.conflictingEndpoint,
      );
    }
    onViolationEnd?.call();
  }
}
