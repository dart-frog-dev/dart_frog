/// Compares routes [a] and [b] to determine whether one is more specific than
/// the other. Longer routes are more specific than shorter routes. A static
/// route segment is more specific than a dynamic route segment.
///
/// Returns 1 if [a] is more specific than [b].
/// Returns -1 if [b] is more specific than [a].
/// Returns 0 if [a] and [b] have the same specificity.
int compareRouteSpecificity(List<String> a, List<String> b) {
  if (a.length != b.length) return a.length > b.length ? 1 : -1;

  for (var i = 0; i < a.length; i++) {
    final segmentA = a[i];
    final segmentB = b[i];

    if (segmentA == segmentB) continue;

    final isADynamic = segmentA.isDynamic;
    final isBDynamic = segmentB.isDynamic;

    if (!isADynamic && isBDynamic) return 1;
    if (isADynamic && !isBDynamic) return -1;
  }

  return 0;
}

/// Extension that helps determine whether a route
/// segment belongs to a dynamic route.
extension IsDynamicRouteExtension on String {
  /// Whether the route part is dynamic.
  bool get isDynamic => startsWith('<') && endsWith('>');
}

/// Extension that helps resolve route segments for a given route.
extension RouteSegmentsExtension on String {
  /// Returns a normalized iterable of path segments.
  Iterable<String> get segments => split('/').skipWhile((s) => s.isEmpty);
}
