[<img src="https://raw.githubusercontent.com/dart-frog-dev/dart_frog/main/assets/dart_frog.png" align="left" height="63.5px" />](https://dart-frog.dev/)

### Dart Frog Test

<br clear="left"/>

[![discord][discord_badge]][discord_link]
[![dart][dart_badge]][dart_link]

[![style: dart frog lint][dart_frog_lint_badge]][dart_frog_lint_link]
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

[dart_badge]: https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=5BB4F0&color=1E2833
[dart_install_link]: https://dart.dev/get-dart
[dart_frog_lint_badge]: https://img.shields.io/badge/style-dart_frog_lint-1DF9D2.svg
[dart_frog_lint_link]: https://pub.dev/packages/dart_frog_lint
[dart_link]: https://dart.dev
[discord_badge]: https://img.shields.io/discord/1394707782271238184?style=for-the-badge&logo=discord&color=1C2A2E&logoColor=1DF9D2
[discord_link]: https://dart-frog.dev/discord
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
