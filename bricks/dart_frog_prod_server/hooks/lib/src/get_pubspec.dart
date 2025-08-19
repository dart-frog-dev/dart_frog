import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

Future<Pubspec> getPubspec(
  String workingDirectory, {
  path.Context? pathContext,
}) async {
  const pubspecYaml = 'pubspec.yaml';
  final pathResolver = pathContext ?? path.context;
  final pubspecFile = File(
    workingDirectory.isEmpty
        ? pubspecYaml
        : pathResolver.join(workingDirectory, pubspecYaml),
  );

  final content = await pubspecFile.readAsString();
  return Pubspec.parse(content);
}
