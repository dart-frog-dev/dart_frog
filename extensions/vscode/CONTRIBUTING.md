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


## 🐸 Releasing Dart Frog’s extension on [VS Code Marketplace](https://marketplace.visualstudio.com/vscode)

1. Go to the **main** branch and ensure it is up to date with the remote (from extensions/vscode):

```bash
git checkout main
git pull
```

2. Run the script that will generate the CHANGELOG for you (from extensions/vscode): 

```bash
sh ../../tool/release_ready.sh <new-version>
```

`<new-version>`: The version of this new extension release, for example: 0.2.1

The [*release_ready*](https://github.com/dart-frog-dev/dart_frog/blob/vscode-v0.2.1/tool/release_ready.sh) script will:

- Create a new branch just for this release and checkout to it.
- Automatically update the [CHANGELOG](https://github.com/dart-frog-dev/dart_frog/blob/main/extensions/vscode/CHANGELOG.md) file with the associated changes.
- Prepares the [package.json](https://github.com/dart-frog-dev/dart_frog/blob/vscode-v0.2.1/extensions/vscode/package.json) and [package.lock.json](https://github.com/dart-frog-dev/dart_frog/blob/vscode-v0.2.1/extensions/vscode/package-lock.json)
3. Manually remove the *(vscode)* scope or others of the conventional commits entries in the CHANGELOG
4. Add the changes and commit with the commit message that the *release_ready* script outputted.
5. Raise a Pull Request, the title should be the same as the commit message outputted by the *release_ready* script.
6. When the Pull Request is merged, tag a new release to the commit. When adding the tag ensure:
    - The tag is pointing to the commit that you recently merged.
    - The title of the tag should be vscode-<new-version>
    - The title of the release should be vscode-<new-version>
    - The description should be a raw copy of the CHANGELOG’s file version’s body you recently crafted (without the version header). If in doubt, see the other released tags as an example.
7. After the release is tagged the release will be performed automatically, check the [actions](https://github.com/dart-frog-dev/dart_frog/actions) tab to see the progress. Once released navigate to the VS Code Marketplace publishers’ page to check the status of the release. 

### 🔨 Troubleshooting VS Code releasing Dart Frog’s extension

- How can I release if the action is not working after tagging a release?

If for any reason the action is not working upon tagging a release you may release manually. To release manually you should:

1. Install [VSCE](https://github.com/microsoft/vscode-vsce) (VS Code Extension Manager):

```bash
npm install --global @vscode/vsce
```

2. Login to VSCE with our credentials:

```bash
vsce login <publisher id>
```

3. Go to the **main** branch and ensure it is up to date with the remote (from extensions/vscode):

```bash
git checkout main
git pull
```

4. Publish the new version manually (from extensions/vscode):

```bash
vsce publish <new-version>
```

`<new-version>`: The version of this new extension release, for example: 0.2.1

5. Once released navigate to the VS Code Marketplace publishers’ page to check the status of the release.
