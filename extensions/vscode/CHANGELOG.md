# 0.2.6

- chore(deps-dev): multiple housekeeping and maintenance updates

# 0.2.5

- chore(deps-dev): multiple housekeeping and maintenance updates

# 0.2.4

- chore(deps): bump semver from 7.5.4 to 7.6.3 in /extensions/vscode ([#1459](https://github.com/dart-frog-dev/dart_frog/pull/1459))
- chore(deps-dev): multiple housekeeping and maintenance updates

# 0.2.3

- chore(deps-dev): bump @types/node from 20.6.0 to 20.6.2 in /extensions/vscode ([#1054](https://github.com/dart-frog-dev/dart_frog/pull/1054))
- chore(deps-dev): bump @typescript-eslint/eslint-plugin from 6.7.0 to 6.7.2 in /extensions/vscode ([#1055](https://github.com/dart-frog-dev/dart_frog/pull/1055))
- chore(deps-dev): bump @typescript-eslint/parser from 6.7.0 to 6.7.2 in /extensions/vscode ([#1057](https://github.com/dart-frog-dev/dart_frog/pull/1057))
- chore(deps-dev): bump sinon from 15.2.0 to 16.0.0 in /extensions/vscode ([#1056](https://github.com/dart-frog-dev/dart_frog/pull/1056))
- fix: windows compatible new route and middleware ([#1062](https://github.com/dart-frog-dev/dart_frog/pull/1062))
- fix: ensure nearestParentDartFrogProject is Windows compatible ([#1064](https://github.com/dart-frog-dev/dart_frog/pull/1064))
- fix: ensure daemon spawns in shell for Windows compatibility ([#1065](https://github.com/dart-frog-dev/dart_frog/pull/1065))
- fix: ensure create command is Windows compatible ([#1068](https://github.com/dart-frog-dev/dart_frog/pull/1068))
- test: used double quotes on create stub ([#1070](https://github.com/dart-frog-dev/dart_frog/pull/1070))

# 0.2.2

- chore: remove new-route-middleware.gif ([#1039](https://github.com/dart-frog-dev/dart_frog/pull/1039))
- fix: detach from debug session on premature application exit ([#1043](https://github.com/dart-frog-dev/dart_frog/pull/1043))
- fix: support async route handlers ([#1041](https://github.com/dart-frog-dev/dart_frog/pull/1041))
- fix: support CodeLens for very long route signatures ([#1046](https://github.com/dart-frog-dev/dart_frog/pull/1046))
- docs: add disclaimer to the extension ([#1047](https://github.com/dart-frog-dev/dart_frog/pull/1047))
- feat: implemented quickPickProject ([#1025](https://github.com/dart-frog-dev/dart_frog/pull/1025))
- fix: avoid keeping progress when spamming stop server ([#1053](https://github.com/dart-frog-dev/dart_frog/pull/1053))
- feat: show quickPickProject on monorepos ([#1026](https://github.com/dart-frog-dev/dart_frog/pull/1026))

# 0.2.1

- docs: update README.md ([#1031](https://github.com/dart-frog-dev/dart_frog/pull/1031))
- chore: rollback engines.vscode version ([#1035](https://github.com/dart-frog-dev/dart_frog/pull/1035))

# 0.2.0

- refactor: use string over String ([#865](https://github.com/dart-frog-dev/dart_frog/pull/865))
- fix: avoid recommending to upgrade when version is above constraints ([#864](https://github.com/dart-frog-dev/dart_frog/pull/864))
- test: use stub.resolves over stub.returns with Promise ([#862](https://github.com/dart-frog-dev/dart_frog/pull/862))
- chore(deps-dev): bump @typescript-eslint/parser from 6.1.0 to 6.2.1 in /extensions/vscode ([#833](https://github.com/dart-frog-dev/dart_frog/pull/833))
- fix: suggest again to install the Dart Frog CLI before running a command that requires of Dart Frog CLI if not installed ([#870](https://github.com/dart-frog-dev/dart_frog/pull/870))
- chore(deps-dev): bump @types/node from 20.4.5 to 20.4.6 in /extensions/vscode ([#876](https://github.com/dart-frog-dev/dart_frog/pull/876))
- chore(deps-dev): bump @types/vscode from 1.80.0 to 1.81.0 in /extensions/vscode ([#888](https://github.com/dart-frog-dev/dart_frog/pull/888))
- refactor: rename command prefix to "dart-frog" ([#895](https://github.com/dart-frog-dev/dart_frog/pull/895))
- chore(deps-dev): bump @types/node from 20.4.6 to 20.4.8 in /extensions/vscode ([#898](https://github.com/dart-frog-dev/dart_frog/pull/898))
- feat: define singleton DartFrogDaemon ([#917](https://github.com/dart-frog-dev/dart_frog/pull/917))
- feat: implement daemon protocol ([#915](https://github.com/dart-frog-dev/dart_frog/pull/915))
- feat: define "daemon" domain messages ([#918](https://github.com/dart-frog-dev/dart_frog/pull/918))
- feat: allow invoking Dart Frog daemon ([#925](https://github.com/dart-frog-dev/dart_frog/pull/925))
- feat: implemented requestIdentifierGenerator for Dart Frog daemon ([#929](https://github.com/dart-frog-dev/dart_frog/pull/929))
- feat: defined dev_server domain ([#931](https://github.com/dart-frog-dev/dart_frog/pull/931))
- feat: defined DartFrogApplication ([#932](https://github.com/dart-frog-dev/dart_frog/pull/932))
- feat: allow daemon to send requests ([#930](https://github.com/dart-frog-dev/dart_frog/pull/930))
- feat: defined DartFrogApplicationRegistry ([#933](https://github.com/dart-frog-dev/dart_frog/pull/933))
- chore(deps-dev): bump @typescript-eslint/parser from 6.2.1 to 6.4.1 in /extensions/vscode ([#947](https://github.com/dart-frog-dev/dart_frog/pull/947))
- chore(deps-dev): bump @types/node from 20.4.8 to 20.5.1 in /extensions/vscode ([#946](https://github.com/dart-frog-dev/dart_frog/pull/946))
- chore(deps-dev): bump @typescript-eslint/eslint-plugin from 6.2.1 to 6.4.1 in /extensions/vscode ([#945](https://github.com/dart-frog-dev/dart_frog/pull/945))
- chore(deps-dev): bump eslint from 8.46.0 to 8.47.0 in /extensions/vscode ([#922](https://github.com/dart-frog-dev/dart_frog/pull/922))
- feat: allow starting the daemon via command ([#943](https://github.com/dart-frog-dev/dart_frog/pull/943))
- chore: include license in packages.json ([#896](https://github.com/dart-frog-dev/dart_frog/pull/896))
- feat: allow starting development server ([#952](https://github.com/dart-frog-dev/dart_frog/pull/952))
- feat: allow stopping development server ([#953](https://github.com/dart-frog-dev/dart_frog/pull/953))
- refactor: allow quickPickApplication to be shared ([#956](https://github.com/dart-frog-dev/dart_frog/pull/956))
- feat: allow attaching development server to Dart debugger ([#955](https://github.com/dart-frog-dev/dart_frog/pull/955))
- refactor: included sort-import and no-unused-vars lint rules ([#962](https://github.com/dart-frog-dev/dart_frog/pull/962))
- chore(deps-dev): bump @typescript-eslint/eslint-plugin from 6.4.1 to 6.5.0 in /extensions/vscode ([#972](https://github.com/dart-frog-dev/dart_frog/pull/972))
- chore(deps-dev): bump @types/node from 20.5.1 to 20.5.7 in /extensions/vscode ([#971](https://github.com/dart-frog-dev/dart_frog/pull/971))
- chore(deps-dev): bump @typescript-eslint/parser from 6.4.1 to 6.5.0 in /extensions/vscode ([#970](https://github.com/dart-frog-dev/dart_frog/pull/970))
- chore(deps-dev): bump eslint from 8.47.0 to 8.48.0 in /extensions/vscode ([#969](https://github.com/dart-frog-dev/dart_frog/pull/969))
- chore(deps-dev): bump typescript from 5.1.6 to 5.2.2 in /extensions/vscode ([#968](https://github.com/dart-frog-dev/dart_frog/pull/968))
- feat: register startDebugDevServer command ([#974](https://github.com/dart-frog-dev/dart_frog/pull/974))
- feat: provide Run CodeLens on route handlers ([#960](https://github.com/dart-frog-dev/dart_frog/pull/960))
- feat: provide Debug CodeLens on route handlers ([#973](https://github.com/dart-frog-dev/dart_frog/pull/973))
- feat: add status bar items to start, stop and open server ([#988](https://github.com/dart-frog-dev/dart_frog/pull/988))
- chore(deps-dev): bump glob from 10.3.3 to 10.3.4 in /extensions/vscode ([#997](https://github.com/dart-frog-dev/dart_frog/pull/997))
- feat: strengthen when clauses with anyDartFrogProjectLoaded ([#1002](https://github.com/dart-frog-dev/dart_frog/pull/1002))
- chore(deps-dev): bump @typescript-eslint/eslint-plugin from 6.5.0 to 6.6.0 in /extensions/vscode ([#999](https://github.com/dart-frog-dev/dart_frog/pull/999))
- feat: added stop to debug toolbar ([#1001](https://github.com/dart-frog-dev/dart_frog/pull/1001))
- chore(deps-dev): bump @typescript-eslint/parser from 6.5.0 to 6.6.0 in /extensions/vscode ([#996](https://github.com/dart-frog-dev/dart_frog/pull/996))
- feat: include host member in DartFrogApplication ([#1010](https://github.com/dart-frog-dev/dart_frog/pull/1010))
- refactor: rename nearestDartFrogProject to nearestParentDartFrogProject ([#1014](https://github.com/dart-frog-dev/dart_frog/pull/1014))
- feat: implemented nearestChildDartFrogProjects ([#1015](https://github.com/dart-frog-dev/dart_frog/pull/1015))
- chore(deps-dev): bump @typescript-eslint/parser from 6.6.0 to 6.7.0 in /extensions/vscode ([#1020](https://github.com/dart-frog-dev/dart_frog/pull/1020))
- chore(deps-dev): bump eslint from 8.48.0 to 8.49.0 in /extensions/vscode ([#1024](https://github.com/dart-frog-dev/dart_frog/pull/1024))
- test: simplify start-dev-server tests ([#1027](https://github.com/dart-frog-dev/dart_frog/pull/1027))
- chore(deps-dev): bump @typescript-eslint/eslint-plugin from 6.6.0 to 6.7.0 in /extensions/vscode ([#1023](https://github.com/dart-frog-dev/dart_frog/pull/1023))
- chore(deps-dev): bump @types/node from 20.5.7 to 20.6.0 in /extensions/vscode ([#1022](https://github.com/dart-frog-dev/dart_frog/pull/1022))
- chore(deps-dev): bump @types/vscode from 1.81.0 to 1.82.0 in /extensions/vscode ([#1021](https://github.com/dart-frog-dev/dart_frog/pull/1021))

# 0.1.1

- docs: update README links and style ([#857](https://github.com/dart-frog-dev/dart_frog/pull/857)).

# 0.1.0

- feat: Initial public release of the Dart Frog VS Code extension 🎉
