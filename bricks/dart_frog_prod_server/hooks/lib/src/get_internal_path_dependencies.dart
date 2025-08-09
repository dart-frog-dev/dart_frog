import 'dart:io' as io;

import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

Future<List<String>> getInternalPathDependencies(io.Directory directory) async {
  final pubspec = await getPubspec(directory.path);

  final internalPathDependencies = pubspec.dependencies.values.where(
    (dependency) {
      if (dependency is! PathDependency) return false;
      return path.isWithin('', dependency.path);
    },
  ).cast<PathDependency>();

  return internalPathDependencies.map((dependency) => dependency.path).toList();
}
