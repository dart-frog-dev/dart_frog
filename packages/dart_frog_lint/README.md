Dart_frog_lint is a developer tool for users of dart_frog, to help spot common mistakes.  
It helps verify that file conventions are properly respected.

## Table of content

- [Table of content](#table-of-content)
- [Installing dart\_frog\_lint](#installing-dart_frog_lint)
- [Enabling/disabling lints.](#enablingdisabling-lints)
  - [Disable one specific rule](#disable-one-specific-rule)
  - [Disable all lints by default](#disable-all-lints-by-default)
- [Running dart\_frog\_lint in the terminal/CI](#running-dart_frog_lint-in-the-terminalci)
- [All the lints](#all-the-lints)
  - [dart\_frog\_entrypoint](#dart_frog_entrypoint)
  - [dart\_frog\_middleware](#dart_frog_middleware)
  - [dart\_frog\_route](#dart_frog_route)

## Installing dart_frog_lint

Dart_frog_lint is implemented using [custom_lint]. As such, it uses custom_lint's installation logic.  
Long story short:

- Add both dart_frog_lint and custom_lint to your `pubspec.yaml`:
  ```yaml
  dev_dependencies:
    custom_lint:
    dart_frog_lint:
  ```
- Enable `custom_lint`'s plugin in your `analysis_options.yaml`:

  ```yaml
  analyzer:
    plugins:
      - custom_lint
  ```

## Enabling/disabling lints.

By default when installing dart_frog_lint, most of the lints will be enabled.
To change this, you have a few options.

### Disable one specific rule

You may dislike one of the various lint rules offered by dart_frog_lint.
In that event, you can explicitly disable this lint rule for your project
by modifying the `analysis_options.yaml`

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    # Explicitly disable one lint rule
    - dart_frog_request: false
```

Note that you can both enable and disable lint rules at once.
This can be useful if your `analysis_options.yaml` includes another one:

```yaml
include: path/to/another/analysis_options.yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    # Enable one rule
    - dart_frog_middleware
    # Disable another
    - dart_frog_request: false
```

### Disable all lints by default

Instead of having all lints on by default and manually disabling lints of your choice,
you can switch to the opposite logic:  
Have lints off by default, and manually enable lints.

This can be done in your `analysis_options.yaml` with the following:

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  # Forcibly disable lint rules by default
  enable_all_lint_rules: false
  rules:
    # You can now enable one specific rule in the "rules" list
    - dart_frog_middleware
```

## Running dart_frog_lint in the terminal/CI

Custom lint rules created by dart_frog_lint may not show-up in `dart analyze`.
To fix this, you can run a custom command line: `custom_lint`.

Since your project should already have custom_lint installed
(cf [installing dart_frog_lint](#installing-dart_frog_lint)), then you should be
able to run:

```sh
dart run custom_lint
```

Alternatively, you can globally install `custom_lint`:

```sh
# Install custom_lint for all projects
dart pub global activate custom_lint
# run custom_lint's command line in a project
custom_lint
```

## All the lints

### dart_frog_entrypoint

The `dart_frog_entrypoint` lint checks that `main.dart` files contain a
valid `run` function. See also [Creating a custom entrypoint](https://dartfrog.vgv.dev/docs/advanced/custom_entrypoint).

**Good**:

```dart
// main.dart
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  // TODO
}
```

**Bad**:

```dart
// An empty main.dart file
// The file must contain a top-level function named "run"
```

```dart
// main.dart

// A "run" function is present, but the return value or parameters are incorrect
void run() {}
```

### dart_frog_middleware

The `dart_frog_middleware` lint checks that `routes/*_middleware.dart` files contain a
valid `middleware` function. See also [Middleware](https://dartfrog.vgv.dev/docs/basics/middleware).

**Good**:

```dart
// routes/my_middleware.dart
Handler middleware(Handler handler) {
  return (context) async {
    // TODO
  };
}
```

**Bad**:

```dart
// routes/my_middleware.dart
// The file must contain a valid top-level "middleware" function
```

```dart
// routes/my_middleware.dart
// The file must contain a valid top-level "middleware" function

// A "middleware" function is present, but the return value or parameters are incorrect
void middleware() {}
```

### dart_frog_route

The `dart_frog_route` lint checks that `routes/*.dart` files contain a
valid `onRequest` function. See also [Routes](https://dartfrog.vgv.dev/docs/basics/routes).

**Good**:

```dart
// routes/hello.dart
Response onRequest(RequestContext context) {
  // TODO
}
```

```dart
// routes/posts/[id].dart
// Dynamic routes are supported too
Response onRequest(RequestContext context, String id) {
  // TODO
}
```

```dart
// routes/example.dart
// Routes can return a Future<T>
Future<Response> onRequest(RequestContext context) async {
  // TODO
}
```

**Bad**:

```dart
//  routes/hello.dart
// The file must contain a valid top-level "onRequest" function
```

```dart
// routes/hello.dart
// An "onRequest" function is present, but the return value or parameters are incorrect
void onRequest() {}
```

```dart
// routes/posts/[id].dart
// The route is a dynamic route, but onRequest doesn't receive the correct number of parameters.
Response onRequest(RequestContext context) {
    // TODO
}
```

[custom_lint]: https://pub.dev/packages/custom_lint
