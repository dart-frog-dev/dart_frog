import 'dart:io';

import 'package:package_config/package_config_types.dart';
import 'package:path/path.dart' as path;

PackageConfig? getPackageConfig(
  String workspaceRoot, {
  path.Context? pathContext,
}) {
  final pathResolver = pathContext ?? path.context;
  final packageConfigFile = File(
    pathResolver.join(workspaceRoot, '.dart_tool/package_config.json'),
  );
  if (!packageConfigFile.existsSync()) return null;

  try {
    final content = packageConfigFile.readAsStringSync();
    return PackageConfig.parseString(content, packageConfigFile.uri);
  } on Exception {
    return null;
  }
}
