# 🦄 Contributing to the Dart Frog Visual Studio Code extension

First of all, thank you for taking the time to contribute! 🎉👍 Before you do, please carefully read this guide.

## Opening an issue

We highly recommend [creating an issue][bug_report_link] if you have found a bug, want to suggest a feature, or recommend a change. Please do not immediately open a pull request. Opening an issue first allows us to reach an agreement on a fix before you put significant effort into a pull request.

When reporting a bug, please use the built-in [Bug Report][bug_report_link] template and provide as much information as possible including detailed reproduction steps. Once one of the package maintainers has reviewed the issue and we reach an agreement on the fix, open a pull request.

## Developing for Dart Frog's Visual Studio Code extension

To develop for the Dart Frog Visual Studio Code (VS Code) extension you will need to become familiar with VS Code extension development and the Very Good Ventures processes and conventions:

### Setting up your local development environment

1. Install a valid [Dart SDK](https://dart.dev/get-dart) in your local environment, it should be compatible with the latest version of [Dart Frog CLI](https://github.com/dart-frog-dev/dart_frog/blob/main/packages/dart_frog_cli/pubspec.yaml). If you have Flutter installed, you likely have a valid Dart SDK version already installed.

2. Install a valid [Node.js](https://nodejs.org) runtime in your local environment, it should be compatible with the [VS Code engine version](./package.json).

3. Open the project in VS Code:

```sh
# Open VS Code (from /extensions/vscode)
code .
```

3. Get all project dependencies:

```sh
# Get project dependencies (from /extensions/vscode)
npm i
```

4. Run all the extension tests:

```sh
# 💻 Run Dart Frog's VS Code extension tests (from /extensions/vscode)
npm test
```

If some tests do not pass out of the box, please submit an [issue](https://github.com/dart-frog-dev/dart_frog/issues/new/choose).

5. Inside the VS Code editor, press F5. This will compile and run the extension in a new **Extension Development Host** window.

6. After a change, make sure to **Run Developer: Reload Window** from the command palette in the new window.

💡 **Note**: For further information about debugging VS Code's extensions refer to the [official documentation](https://code.visualstudio.com/api/get-started/your-first-extension).

### Creating a Pull Request

Before creating a Pull Request please:

1. [Fork](https://docs.github.com/en/get-started/quickstart/contributing-to-projects) the [GitHub repository](https://github.com/dart-frog-dev/dart_frog) and create your branch from `main`:

```sh
# 🪵 Branch from `main`
git branch <branch-name>
git checkout <branch-name>
```

2. Ensure you have a meaningful [semantic][conventional_commits_link] commit message.

3. Analyze your code:

```sh
# 🔍 Run ESLint linter
npm run lint
```

4. Ensure all tests are passing and that coverage is 100%:

```sh
# 💻 Run Dart Frog's VS Code extension tests (from /extensions/vscode)
npm test
```

💡 **Note**: As contributors we should avoid cross-test dependencies. We rely on Mocha as our testing framework, unfortunately, it doesn't yet support [randomized test ordering](https://github.com/mochajs/mocha/issues/902).

5. Create the Pull Request with a meaningful description, linking to the original issue where possible.

6. Verify that all [status checks](https://github.com/dart-frog-dev/dart_frog/actions/) are passing for your Pull Request once they have been approved to run by a maintainer.

💡 **Note**: While the prerequisites above must be satisfied prior to having your pull request reviewed, the reviewer(s) may ask you to complete additional work, tests, or other changes before your pull request can be accepted.

[conventional_commits_link]: https://www.conventionalcommits.org/en/v1.0.0
[bug_report_link]: https://github.com/dart-frog-dev/dart_frog/issues/new?assignees=&labels=bug&template=bug_report.md&title=fix%3A+
