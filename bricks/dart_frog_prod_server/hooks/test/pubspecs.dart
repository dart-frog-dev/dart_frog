/// An artificially crafted `pubspec.yaml` file with:
///
/// * A direct main path dependency that is a child of the project directory.
/// * Dart workspaces enabled
const workspaceRoot = '''
name: _
dependencies:
  server:
    path: packages/server  
workspace:
  - packages/server
''';

/// An artificially crafted `pubspec.yaml` file with:
///
/// * Dart workspaces enabled
const workspaceChild = '''
name: server
resolution: workspace
''';
