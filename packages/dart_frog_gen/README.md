[<img src="https://raw.githubusercontent.com/dart-frog-dev/dart_frog/main/assets/dart_frog.png" align="left" height="63.5px" />](https://dart-frog.dev/)

### Dart Frog Gen

<br clear="left"/>

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

Code generation tooling for [Dart Frog][dart_frog_link].

[Originally developed][credits_link] by [Very Good Ventures][very_good_ventures_link] 🦄

```dart
import 'dart:io';

import 'package:dart_frog_gen/dart_frog_gen.dart';

void main() {
  final routeConfiguration = buildRouteConfiguration(Directory.current);
  // Use the route configuration...
}
```

[ci_badge]: https://github.com/dart-frog-dev/dart_frog/actions/workflows/dart_frog_gen.yaml/badge.svg?branch=main
[ci_link]: https://github.com/dart-frog-dev/dart_frog/actions/workflows/dart_frog_gen.yaml
[coverage_badge]: https://raw.githubusercontent.com/dart-frog-dev/dart_frog/main/packages/dart_frog_gen/coverage_badge.svg
[credits_link]: https://github.com/dart-frog-dev/dart_frog/blob/main/CREDITS.md#acknowledgments
[dart_frog_link]: https://github.com/dart-frog-dev/dart_frog
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/dart-frog-dev/dart_frog/main/assets/dart_frog_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/dart-frog-dev/dart_frog/main/assets/dart_frog_logo_white.png#gh-dark-mode-only
[pub_badge]: https://img.shields.io/pub/v/dart_frog_gen.svg
[pub_link]: https://pub.dartlang.org/packages/dart_frog_gen
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_ventures_link]: https://verygood.ventures
