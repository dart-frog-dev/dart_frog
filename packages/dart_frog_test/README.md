[<img src="https://raw.githubusercontent.com/dart-frog-dev/dart_frog/main/assets/dart_frog.png" align="left" height="63.5px" />](https://dart-frog.dev/)

### Dart Frog Test

<br clear="left"/>

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]

A testing library that makes it easy to test Dart Frog services. It offers helpers to mock requests as well as
custom matchers in order to write readable expectations.

> [!NOTE]
> This package is still experimental and although it is ready to be used, some/or all of its API
> might change (with deprecations) in future versions.

## Installation 💻

**❗ In order to start using Dart Frog Test you must have the [Dart SDK][dart_install_link] installed on your machine.**

Add `dart_frog_test` to your `pubspec.yaml`:

```yaml
dependencies:
  dart_frog_test:
```

Install it:

```sh
dart pub get
```

## TestRequestContext

This class makes it simple to mock a `RequestContext` for a Dart Frog request handler. To use it, simply import it
and use its constructor and methods to create the mocker context.

A simple example:

```dart
// Mocking a get request, which is the default
import '../../../routes/users/[id].dart' as route;

test('returns ok', () {
  final context = TestRequestContext(
    path: '/users/1',
  );

  final response = route.onRequest(context);
  expect(response.statusCode, equals(200));
});
```

If the route handler function reads a [dependency injected via context](https://dart-frog.dev/basics/dependency-injection), that can also be mocked:

```dart
// Mocking a get request, which is the default
import '../../../routes/users/index.dart' as route;

test('returns ok', () {
  final context = TestRequestContext(
    path: '/users',
  );

  final userRepository = /* Create Mock */;

  context.provide<UserRepository>(userRepository);

  final response = route.onRequest(context);
  expect(response.statusCode, equals(200));
});
```

Check the `TestRequestContext` [constructor](https://pub.dev/documentation/dart_frog_test/latest/) for all the available context attributes that can be mocked.

## Matchers

This package also provide test matchers that can be used to do expectation or assertions on top of
Dart Frog's `Response`s:

```dart
expectJsonBody(response, {'name': 'Hank'});
expectBody(response, 'Hank');

expect(response, isOk);
expect(response, isBadRequest);
expect(response, isCreated);
expect(response, isNotFound);
expect(response, isUnauthorized);
expect(response, isForbidden);
expect(response, isInternalServerError);
expect(response, hasStatus(301));

await expectNotAllowedMethods(
  route.onRequest,
  contextBuilder: (method) => TestRequestContext(
    path: '/dice',
    method: method,
  ),
  allowedMethods: [HttpMethod.post],
);
```

---

[credits_link]: https://github.com/dart-frog-dev/dart_frog/blob/main/CREDITS.md#acknowledgments
[dart_install_link]: https://dart.dev/get-dart
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[mason_link]: https://github.com/felangel/mason
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
