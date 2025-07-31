[![Dart Frog Logo][logo_black]][dart_frog_link_light]

> ✏️ Note: The extension is currently in the early stages, if you experience issues or have a recommendation we are eager to hear from you [here](https://github.com/VeryGoodOpenSource/dart_frog/issues/new/choose)!

This is the [Dart Frog](https://dart-frog.dev/) [VS Code](https://code.visualstudio.com/) extension, which provides tools for effectively managing Dart Frog projects.

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄

## Installation

Dart Frog can be installed from the [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=VeryGoodVentures.dart-frog) or by [searching within VS Code](https://code.visualstudio.com/docs/editor/extension-gallery#_search-for-an-extension).

## Demonstration

![demonstration](https://raw.githubusercontent.com/VeryGoodOpenSource/dart_frog/main/extensions/vscode/assets/demonstration.gif)

## Commands

| Command                                         | Description                          | Launch from                             |
| ----------------------------------------------- | ------------------------------------ | --------------------------------------- |
| `Dart Frog: Create`                             | Creates a new Dart Frog app          | Command Palette or Context Menu         |
| `Dart Frog: Install CLI`                        | Installs Dart Frog CLI               | Command Palette                         |
| `Dart Frog: Update CLI`                         | Updates Dart Frog CLI                | Command Palette                         |
| `Dart Frog: New Route`                          | Generates a new route                | Command Palette or Context Menu         |
| `Dart Frog: New Middleware`                     | Generates a new middleware           | Command Palette or Context Menu         |
| `Dart Frog: Start Daemon`                       | Starts the Dart Frog daemon          | Command Palette                         |
| `Dart Frog: Start Development Server`           | Starts a Dart Frog server            | Command Palette, CodeLens or Status Bar |
| `Dart Frog: Debug Development Server`           | Debugs a Dart Frog server            | Command Palette                         |
| `Dart Frog: Start and Debug Development Server` | Starts and debugs a Dart Frog server | Command Palette or CodeLens             |
| `Dart Frog: Stop Development Server`            | Stops a Dart Frog server             | Command Palette or Status Bar           |

## Configuration

| Name                       | Description                                         | Type    | Default |
| -------------------------- | --------------------------------------------------- | ------- | ------- |
| `dart-frog.enableCodeLens` | Whether or not to enable [CodeLens][code_lens_link] | Boolean | True    |

[ci_link]: https://github.com/VeryGoodOpenSource/dart_frog/actions/workflows/main.yaml
[dart_frog_link_light]: https://github.com/verygoodopensource/dart_frog
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VeryGoodOpenSource/dart_frog/main/assets/dart_frog_logo_black.png
[very_good_ventures_link]: https://verygood.ventures
[code_lens_link]: https://code.visualstudio.com/blogs/2017/02/12/code-lens-roundup
