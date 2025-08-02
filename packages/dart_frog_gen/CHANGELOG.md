# 2.0.1

- refactor: upgrade analysis options ([#1798](https://github.com/dart-frog-dev/dart_frog/pull/1798))
- docs: update all repository references ([#1791](https://github.com/dart-frog-dev/dart_frog/pull/1791))

# 2.0.0

- feat: removing external checking from code gen ([#928](https://github.com/dart-frog-dev/dart_frog/pull/928))
- chore(packages): bump very good analysis ([#983](https://github.com/dart-frog-dev/dart_frog/pull/983))

# 1.1.0

- chore(deps): bump `package:mocktail` and `very_good_analysis` ([#855](https://github.com/dart-frog-dev/dart_frog/pull/855))
- feat(dart_frog_gen): add `toJson` to `RouteConfig` ([#872](https://github.com/dart-frog-dev/dart_frog/pull/872))

# 1.0.0

- feat: detect conflict between dynamic routes and non dynamic ones

# 0.4.1

- feat: update to Dart 3 and Very Good Analysis 5 ([#681](https://github.com/dart-frog-dev/dart_frog/pull/681))
- feat: adding wildcard detection to dart frog gen ([#691](https://github.com/dart-frog-dev/dart_frog/pull/691))

# 0.4.0

- feat!: re-land "add route configuration validation to gen" ([#614](https://github.com/dart-frog-dev/dart_frog/pull/614))

# 0.3.4

- fix: revert "add route configuration validation to gen" ([#628](https://github.com/dart-frog-dev/dart_frog/pull/628))

# 0.3.3

- feat: add route configuration validation to gen ([#614](https://github.com/dart-frog-dev/dart_frog/pull/614))

# 0.3.2

- feat: detect custom init method ([#564](https://github.com/dart-frog-dev/dart_frog/pull/564))

# 0.3.1

- deps: upgrade to `Dart ">=2.19.0 <3.0.0"`
- deps: upgrade to `very_good_analysis ^4.0.0`

# 0.3.0

- **BREAKING** fix: support for cascading middleware
  - `RouteDirectory` signature for `middleware` changed from `MiddlewareFile?` -> `List<MiddlewareFile>`
- perf: exclude route directories with no routes

# 0.2.0

- **BREAKING** feat: support for mounting dynamic routes
- **BREAKING** deps: upgrade to `Dart ">=2.18.0 <3.0.0"`
- deps: upgrade to `very_good_analysis ^3.1.0`

# 0.1.0

- chore: stable 0.1.0 release

# 0.0.2-dev.8

- fix: do not report rogue route if index.dart exists
- feat: add `invokeCustomEntrypoint` to `RouteConfiguration`

# 0.0.2-dev.7

- fix: detect rogue routes
- fix: support repeated nested routes

# 0.0.2-dev.6

- fix: windows relative import syntax

# 0.0.2-dev.5

- feat: include `endpoints` in `RouteConfiguration`
- refactor: make `buildRouteConfiguration` relative to `routes`
- docs: pubspec `homepage`, `repository`, `issue_tracker`, and `documentation` links

# 0.0.2-dev.4

- fix: nested dynamic directory resolution

# 0.0.2-dev.3

- feat: add `serveStaticFiles` to `RouteConfiguration`

# 0.0.2-dev.2

- fix: windows route generation

# 0.0.2-dev.1

- **BREAKING**: fix: use `[...]` instead of `<...>` for dynamic routes

# 0.0.1-dev.4

- fix: append missing `/` route prefix

# 0.0.1-dev.3

- docs: add example and improve documentation

# 0.0.1-dev.2

- docs: fix README assets

# 0.0.1-dev.1

- feat: initial experimental release 🎉
