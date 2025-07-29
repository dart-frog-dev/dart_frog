[![Dart Frog Logo][logo_white]][dart_frog_link_dark]
[![Dart Frog Logo][logo_black]][dart_frog_link_light]

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)

A fast, minimalistic backend framework for Dart 🎯

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄

## Acknowledgments

Originally, Dart Frog was developed by [Very Good Ventures](https://verygood.ventures/) and then transferred to the Dart Frog organization; learn more on ["Dart Frog leaves the pond" blog](BLOG-URL).

## Documentation 📝

For official documentation, please visit https://dartfrog.vgv.dev.

## Packages 📦

| Package                                                                                                         | Pub                                                                                                                    |
| --------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| [dart_frog](https://github.com/verygoodopensource/dart_frog/tree/main/packages/dart_frog)                       | [![pub package](https://img.shields.io/pub/v/dart_frog.svg)](https://pub.dev/packages/dart_frog)                       |
| [dart_frog_gen](https://github.com/verygoodopensource/dart_frog/tree/main/packages/dart_frog_gen)               | [![pub package](https://img.shields.io/pub/v/dart_frog_gen.svg)](https://pub.dev/packages/dart_frog_gen)               |
| [dart_frog_cli](https://github.com/verygoodopensource/dart_frog/tree/main/packages/dart_frog_cli)               | [![pub package](https://img.shields.io/pub/v/dart_frog_cli.svg)](https://pub.dev/packages/dart_frog_cli)               |
| [dart_frog_web_socket](https://github.com/verygoodopensource/dart_frog/tree/main/packages/dart_frog_web_socket) | [![pub package](https://img.shields.io/pub/v/dart_frog_web_socket.svg)](https://pub.dev/packages/dart_frog_web_socket) |
| [dart_frog_auth](https://github.com/verygoodopensource/dart_frog/tree/main/packages/dart_frog_auth)             | [![pub package](https://img.shields.io/pub/v/dart_frog_auth.svg)](https://pub.dev/packages/dart_frog_auth)             |


## Quick Start 🚀

### Prerequisites 📝

In order to use Dart Frog you must have the [Dart SDK][dart_installation_link] installed on your machine.

### Installing 🧑‍💻

```sh
# 📦 Install the dart_frog cli from pub.dev
dart pub global activate dart_frog_cli
```

### Creating a Project ✨

Use the `dart_frog create` command to create a new project.

```sh
# 🚀 Create a new project called "my_project"
dart_frog create my_project
```

### Start the Dev Server 🏁

Next, open the newly created project and start the dev server via:

```sh
# 🏁 Start the dev server
dart_frog dev
```

💡 **Tip**: By default port `8080` is used. A custom port can be used via the `--port` option.

### Create a Production Build 📦

Create a production build which includes a `DockerFile` so that you can deploy anywhere:

```sh
# 📦 Create a production build
dart_frog build
```

### Create New Routes and Middleware 🛣️

To add new routes and middleware to your project, use the `dart_frog new` command.

```sh
# 🛣️ Create a new route "/hello/world"
dart_frog new route "/hello/world"

# 🛣️ Create a new middleware for the route "/hello/world"
dart_frog new middleware "/hello/world"
```

## Goals 🎯

Dart Frog is built on top of [shelf](https://pub.dev/packages/shelf) and [mason](https://pub.dev/packages/mason) and is inspired by many tools including [remix.run](https://remix.run), [next.js](https://nextjs.org), and [express.js](https://expressjs.com).

The goal of Dart Frog is to help developers effectively build backends in Dart. Currently, Dart Frog is focused on optimizing the process of building backends which aggregate, compose, and normalize data from multiple sources.

Dart Frog provides a simple core with a small API surface area in order to reduce the learning curve and ramp-up time for developers. In addition, Dart Frog is intended to help Flutter/Dart developers maximize their productivity by having a unified tech stack that enables sharing tooling, models, and more!

## Extensions 💻

- [VS Code](https://marketplace.visualstudio.com/items?itemName=VeryGoodVentures.dart-frog): extends VS Code with support for Dart Frog and provides tools for effectively managing Dart Frog projects within VS Code.

[dart_installation_link]: https://dart.dev/get-dart
[ci_badge]: https://github.com/VeryGoodOpenSource/dart_frog/actions/workflows/main.yaml/badge.svg
[ci_link]: https://github.com/VeryGoodOpenSource/dart_frog/actions/workflows/main.yaml
[coverage_badge]: https://raw.githubusercontent.com/VeryGoodOpenSource/dart_frog/main/packages/dart_frog/coverage_badge.svg
[dart_frog_link_dark]: https://github.com/verygoodopensource/dart_frog#gh-dark-mode-only
[dart_frog_link_light]: https://github.com/verygoodopensource/dart_frog#gh-light-mode-only
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VeryGoodOpenSource/dart_frog/main/assets/dart_frog_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VeryGoodOpenSource/dart_frog/main/assets/dart_frog_logo_white.png#gh-dark-mode-only
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_ventures_link]: https://verygood.ventures
