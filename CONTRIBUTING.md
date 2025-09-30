# Contributing to Dart Frog

First off, thanks for taking the time to contribute! 🎉👍

These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

This project is opinionated and follows patterns and practices used by the team at [Very Good Ventures][very_good_ventures_link].

## Understanding the Dart Frog repository

This is a mono repo, a repository that includes more than one individual project. In fact, the Dart Frog repository includes all the packages, example apps, CLIs, and IDE integration plugins that have a role in the Dart Frog developer experience.

The contents of the mono repo is divided into the following directories:

- [`tool/`](https://github.com/dart-frog-dev/dart_frog/tree/main/tool): contains internal operation scripts
- [`assets/`](https://github.com/dart-frog-dev/dart_frog/tree/main/assets): images to embed into READMEs
- [`docs/`](https://github.com/dart-frog-dev/dart_frog/tree/main/docs): source code for the [docs site][dart_frog_site].
- [`examples/`](https://github.com/dart-frog-dev/dart_frog/tree/main/examples): example projects of some of the several usages of Dart Frog
- [`extensions/`](https://github.com/dart-frog-dev/dart_frog/tree/main/extensions): Integrations with IDEs such as VSCode.
- [`bricks/`](https://github.com/dart-frog-dev/dart_frog/tree/main/bricks): Internal mason bricks used by [dart_frog_cli][dart_frog_cli_link] to perform tasks such as creating new projects, starting a dev server, and building a prod server.
- [`packages/`](https://github.com/dart-frog-dev/dart_frog/tree/main/packages): The source code of the packages that constitute the Dart Frog suite (`dart_frog_cli`, `dart_frog` and `dart_frog_gen`) as well as companion packages (such as `dart_frog_web_socket`).

Some of the included projects have more specific instructions on contribution. In these cases, the project root may include a `CONTRIBUTING.md` file with such instructions.

## Proposing a changes & reporting bugs

If you intend to change the public API or make any non-trivial changes to the implementation, we recommend filing an issue. This lets us reach an agreement on your proposal before you put significant effort into it.

If you’re only fixing a bug, it’s fine to submit a pull request right away but we still recommend to [filing an issue][issue_creation_link] detailing what you’re fixing. This is helpful in case we don’t accept that specific fix but want to keep track of the issue. Please use the built-in [Bug Report][bug_report_link] template and provide as much information as possible including detailed reproduction steps. Once one of the package maintainers has reviewed the issue and an agreement is reached regarding the fix, a pull request can be created.

## Creating a Pull Request

Before creating a pull request please:

1. Fork the repository and create your branch from `main`.
1. Install all dependencies (`dart pub get`).
1. Squash your commits and ensure you have a meaningful, [semantic][conventional_commits_link] commit message.
1. Add tests! Pull Requests without 100% test coverage will not be approved.
1. Ensure the existing test suite passes locally.
1. Format your code (`dart format .`).
1. Analyze your code (`dart analyze --fatal-infos --fatal-warnings .`).
1. Create the Pull Request.
1. Verify that all status checks are passing.

While the prerequisites above must be satisfied prior to having your
pull request reviewed, the reviewer(s) may ask you to complete additional
work, tests, or other changes before your pull request can be ultimately
accepted.

# Maintaining Dart Frog

## Setting up your local development environment

Prerequisites:

- Install a valid [Dart SDK](https://dart.dev/get-dart) in your local environment, it should be compatible with the latest version of [Dart Frog CLI](https://github.com/dart-frog-dev/dart_frog/blob/main/packages/dart_frog_cli/pubspec.yaml). If you have Flutter installed, you likely have a valid Dart SDK version already installed.
- [Mason CLI][mason_install_link] (to run and test the `bricks`);
- [Node.js][node_js_dowload_link], for working with the VSCode extension or the documentation website. Refer to their CONTRIBUTING files for further installation requirements.
- Capability to run shell scripts (for the scripts under `tool/`).

## Understanding the `packages/` contents:

### `dart_frog`

This is the user-facing package of the Dart Frog SDK, which means that Dart Frog users will be using its API to construct servers and runtime operations. It contains logic for request parsing, middleware, and response creation.

### `dart_frog_gen`

This is the internal package used by the Dart Frog tooling to interpret the file disposition and from it construct a Dart Frog server.

> :warning: **Warning**: this package is a dependency on the bricks bundled into the CLI. This means that any changes that break the bricks should be released with a major version, otherwise dart frog users may be blocked from performing tasks such as `dev`, `build`, and `new`.

### `dart_frog_cli`

A Dart command line interface package that serves as the main tool for Dart Frog. It includes bundled versions of the bricks under `bricks/`. To sync the source code of the bricks with new bundles, run `tool/generate_bundles.sh`.

### Companion packages

The other items under `packages/` are companion packages in which dart_frog users may include on their project for specific server-side capabilities, such as auth (`dart_frog_auth`) and WebSockets (`dart_frog_web_socket`)

## Releasing versions of packages

Before starting the release process of an individual package, first check:

1. If your local `main` branch is up to date:

```shell
# ☁️ Ensure you're up to date with the GitHub remote
git checkout main
git fetch
git status
```

2. Ensure the [GitHub pipeline](https://github.com/dart-frog-dev/dart_frog/actions) is green (has passed successfully) for your given package.

3. Run the script under `tool/release_ready.sh` within the package root repository and the desired new version.

```shell
# 🚀 Run the release ready script (from packages/<package>)
../../tool/release_ready.sh <version>
```

The above example will: update the version of `<package>` to `<version>`, update the dart_frog CHANGELOG.md, create and checkout to a local release branch.

4. Review the recently updated CHANGELOG file. You should manually amend the content were necessary. For example, by removing the redundant scope of some semantic pull requests or removing superfluous or unrelated logged changes.

5. Commit, push and open a pull request from the new release branch.

6. Once merged, create a [release on GitHub][github_release_link]. The [publish workflow](https://github.com/dart-frog-dev/dart_frog/blob/main/.github/workflows/publish.yaml) should take care of publishing the new version on the appropriate package manager.

7. Open follow-up pull requests updating this package usage in any other Dart Frog package that depends on this new release.

[conventional_commits_link]: https://www.conventionalcommits.org/en/v1.0.0
[bug_report_link]: https://github.com/dart-frog-dev/dart_frog/issues/new?assignees=&labels=bug&projects=&template=bug_report.md&title=fix%3A+
[issue_creation_link]: https://github.com/dart-frog-dev/dart_frog/issues/new/choose
[very_good_ventures_link]: https://verygood.ventures
[dart_frog_site]: https://dart-frog.dev/
[dart_frog_cli_link]: https://pub.dev/packages/dart_frog_cli
[node_js_dowload_link]: https://nodejs.org/pt-br/download
[mason_install_link]: https://docs.brickhub.dev/installing/
[dart_standalone_link]: https://dart.dev/get-dart
[dart_on_flutter_link]: https://docs.flutter.dev/get-started/install
[github_release_link]: https://github.com/dart-frog-dev/dart_frog/releases
