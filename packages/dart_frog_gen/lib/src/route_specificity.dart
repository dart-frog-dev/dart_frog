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

/// Compares route directories [a] and [b] to determine the order in which
/// their routers should be mounted on the root router.
///
/// Unlike [compareRouteSpecificity] (which orders sibling route *files* within
/// a single router), this orders the flat list of directory mounts registered
/// on the root router. Because `Router.mount('/prefix', ...)` also matches
/// `'/prefix/<rest>'` and falls through on a 404, a mount must be registered
/// *before* any shorter prefix mount that could otherwise capture its path via
/// a dynamic child. Each path segment is ranked so the most specific mount is
/// registered first:
///
/// * a static segment (rank 2) is more specific than a shorter route that ends
///   here (rank 1), so `'/tasks/add'` is registered before `'/tasks'`;
/// * a shorter route that ends here (rank 1) is more specific than a dynamic
///   segment (rank 0), so `'/books'` is registered before `'/books/<id>'`.
///
/// Returns a negative value if [a] should be registered before [b], a positive
/// value if [b] should be registered before [a], and `0` if they are equally
/// specific.
int compareRouteDirectorySpecificity(List<String> a, List<String> b) {
  final maxLength = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < maxLength; i++) {
    final rankA = i < a.length ? (a[i].isDynamic ? 0 : 2) : 1;
    final rankB = i < b.length ? (b[i].isDynamic ? 0 : 2) : 1;
    if (rankA != rankB) return rankB - rankA;
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
