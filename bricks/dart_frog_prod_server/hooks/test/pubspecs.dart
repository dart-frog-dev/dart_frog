/// An artificially crafted `pubspec.lock` file with:
///
/// * A direct main path dependency that is not a child of the project
/// directory.
/// * A direct main path dependency that is not a child of the project
/// directory and has a different package name than the directory name.
/// * A direct main dependency that is hosted.
/// * A direct dev main dependency that is hosted.
/// * A direct overridden dependency from git.
const fooPath = '''
name: _
dependencies:
  foo:
    path: ../../foo
  foo2:
    path: ../../foo2
  direct_main: ^0.1.0-dev.50
dev_dependencies:
  test: ^1.0.0
dependency_overrides:
  direct_overridden:
    git:
      url: https://github.com/alestiago/mason
      path: packages/mason
      ref: 72c306a8d8abf306b5d024f95aac29ba5fd96577
''';

/// An artificially crafted `pubspec.lock` file with:
///
/// * A direct main path dependency that is not a child of the project
/// directory.
/// * A direct main path dependency that is a child of the project directory.
/// * A direct main dependency that is hosted.
/// * A direct dev main dependency that is hosted.
const fooPathWithInternalDependency = '''
name: _
dependencies:
  foo:
    path: ../../foo
  bar:
    path: packages/bar
  mason: ^0.1.0-dev.50
dev_dependencies:
  test: ^1.0.0
''';

/// An artificially crafted `pubspec.lock` file with:
///
/// * A direct main dependency that is hosted.
/// * A direct dev main dependency that is hosted.
const noPathDependencies = '''
name: _
dependencies:
  mason: ^0.1.0-dev.50
dev_dependencies:
  test: ^1.0.0
''';
