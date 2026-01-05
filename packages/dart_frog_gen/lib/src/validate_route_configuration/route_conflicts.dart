import 'package:dart_frog_gen/dart_frog_gen.dart';
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

bool _isDynamic(String part) => part.startsWith('<') && part.endsWith('>');

bool _overlaps(List<String> routeA, List<String> routeB) {
  if (routeA.length != routeB.length) return false;

  for (var i = 0; i < routeA.length; i++) {
    final segmentA = routeA[i];
    final segmentB = routeB[i];

    if (segmentA == segmentB) continue;

    // Dynamic segments can match any value
    if (_isDynamic(segmentA) || _isDynamic(segmentB)) continue;

    // Two different static segments can never match the same path
    return false;
  }

  return true;
}

/// Returns true if `routeA` is at least as specific as `routeB`
/// at every segment, and more specific in at least one segment.
///
/// Static segments are more specific than dynamic ones.
bool _dominates(List<String> routeA, List<String> routeB) {
  var hasStrictAdvantage = false;

  for (var i = 0; i < routeA.length; i++) {
    final segmentA = routeA[i];
    final segmentB = routeB[i];

    if (segmentA == segmentB) continue;

    final aIsDynamic = _isDynamic(segmentA);
    final bIsDynamic = _isDynamic(segmentB);

    // A cannot dominate B if A is dynamic and B is static
    if (aIsDynamic && !bIsDynamic) return false;

    // A is strictly more specific at this segment
    if (!aIsDynamic && bIsDynamic) {
      hasStrictAdvantage = true;
    }
  }

  return hasStrictAdvantage;
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
        final keyParts = entry.key.split('/');

        final matches = configuration.endpoints.keys.where((other) {
          if (other == entry.key) return false;

          final otherParts = other.split('/');

          if (!_overlaps(keyParts, otherParts)) return false;

          // If either route is strictly more specific than the other,
          // the overlap can be resolved by deterministic route ordering.
          final aDominatesB = _dominates(keyParts, otherParts);
          final bDominatesA = _dominates(otherParts, keyParts);

          // Flag as conflict when neither dominates
          return !aDominatesB && !bDominatesA;
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
