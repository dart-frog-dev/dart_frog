import 'dart:async';
import 'dart:io' as io;

import 'package:dart_frog_gen/dart_frog_gen.dart';
import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';
import 'package:io/io.dart' as io_expanded;
import 'package:mason/mason.dart'
    show HookContext, defaultForeground, lightCyan;
import 'package:path/path.dart' as path;

typedef RouteConfigurationBuilder = RouteConfiguration Function(
  io.Directory directory,
);

Future<void> run(HookContext context) => preGen(context);

Future<void> preGen(
  HookContext context, {
  io.Directory? directory,
  ProcessRunner runProcess = io.Process.run,
  RouteConfigurationBuilder buildConfiguration = buildRouteConfiguration,
  void Function(int exitCode) exit = defaultExit,
  Future<void> Function(String from, String to) copyPath = io_expanded.copyPath,
}) async {
  final projectDirectory = directory ?? io.Directory.current;
  final usesWorkspaces = usesWorkspaceResolution(
    context,
    workingDirectory: projectDirectory.path,
    exit: exit,
  );

  // We need to make sure that the pubspec.lock file is up to date
  await dartPubGet(
    context,
    workingDirectory: projectDirectory.path,
    runProcess: runProcess,
    exit: exit,
  );

  final buildDirectory = io.Directory(
    path.join(projectDirectory.path, 'build'),
  );

  await createBundle(
    context: context,
    projectDirectory: projectDirectory,
    buildDirectory: buildDirectory,
    exit: exit,
  );

  if (usesWorkspaces) {
    // Disable workspace resolution until we can generate per-package lockfiles.
    // https://github.com/dart-lang/pub/issues/4594
    disableWorkspaceResolution(
      context,
      buildDirectory: buildDirectory.path,
      exit: exit,
    );
    // Copy the pubspec.lock from the workspace root to ensure the same versions
    // of dependencies are used in the production build.
    copyWorkspacePubspecLock(
      context,
      buildDirectory: buildDirectory.path,
      workingDirectory: projectDirectory.path,
      exit: exit,
    );
    // Adjust all relative pubspec.yaml imports.
    adjustRelativePubspecImports(
      context,
      buildDirectory: buildDirectory.path,
      exit: exit,
    );
  }

  // We need to make sure that the pubspec.lock file is up to date
  await dartPubGet(
    context,
    workingDirectory: buildDirectory.path,
    runProcess: runProcess,
    exit: exit,
  );

  final RouteConfiguration configuration;
  try {
    configuration = buildConfiguration(projectDirectory);
  } on Exception catch (error) {
    context.logger.err('$error');
    return exit(1);
  }

  reportRouteConflicts(
    configuration,
    onRouteConflict: (
      originalFilePath,
      conflictingFilePath,
      conflictingEndpoint,
    ) {
      context.logger.err(
        '''Route conflict detected. ${lightCyan.wrap(originalFilePath)} and ${lightCyan.wrap(conflictingFilePath)} both resolve to ${lightCyan.wrap(conflictingEndpoint)}.''',
      );
    },
    onViolationEnd: () => exit(1),
  );

  reportRogueRoutes(
    configuration,
    onRogueRoute: (filePath, idealPath) {
      context.logger.err(
        '''Rogue route detected.${defaultForeground.wrap(' ')}Rename ${lightCyan.wrap(filePath)} to ${lightCyan.wrap(idealPath)}.''',
      );
    },
    onViolationEnd: () => exit(1),
  );

  final internalPathDependencies = await getInternalPathDependencies(
    buildDirectory,
  );

  final externalDependencies = await createExternalPackagesFolder(
    projectDirectory: projectDirectory,
    buildDirectory: buildDirectory,
    copyPath: copyPath,
  );

  final customDockerFile = io.File(
    path.join(buildDirectory.path, 'Dockerfile'),
  );
  final addDockerfile = !customDockerFile.existsSync();

  context.vars = {
    'directories': configuration.directories
        .map((c) => c.toJson())
        .toList()
        .reversed
        .toList(),
    'routes': configuration.routes.map((r) => r.toJson()).toList(),
    'middleware': configuration.middleware.map((m) => m.toJson()).toList(),
    'globalMiddleware': configuration.globalMiddleware != null
        ? configuration.globalMiddleware!.toJson()
        : false,
    'serveStaticFiles': configuration.serveStaticFiles,
    'invokeCustomEntrypoint': configuration.invokeCustomEntrypoint,
    'invokeCustomInit': configuration.invokeCustomInit,
    'pathDependencies': internalPathDependencies,
    'hasExternalDependencies': externalDependencies.isNotEmpty,
    'dartVersion': context.vars['dartVersion'],
    'addDockerfile': addDockerfile,
  };
}
