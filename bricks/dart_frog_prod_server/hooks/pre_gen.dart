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

  VoidCallback? restoreWorkspaceResolution;
  VoidCallback? revertPubspecLock;

  if (usesWorkspaces) {
    final workspaceRoot = getWorkspaceRoot(projectDirectory.path);
    if (workspaceRoot == null) {
      context.logger.err(
        'Unable to determine workspace root for ${projectDirectory.path}',
      );
      return exit(1);
    }

    // We need to make sure the package_config.json is up to date.
    await dartPubGet(
      context,
      message: 'Generating package graph',
      workingDirectory: projectDirectory.path,
      runProcess: runProcess,
      exit: exit,
    );

    final packageConfig = getPackageConfig(workspaceRoot.path);
    if (packageConfig == null) {
      context.logger.err(
        'Unable to find package_config.json for ${workspaceRoot.path}',
      );
      return exit(1);
    }

    final packageGraph = getPackageGraph(workspaceRoot.path);
    if (packageGraph == null) {
      context.logger.err(
        'Unable to find package_graph.json for ${workspaceRoot.path}',
      );
      return exit(1);
    }

    // Disable workspace resolution until we can generate per-package lockfiles.
    // https://github.com/dart-lang/pub/issues/4594
    restoreWorkspaceResolution = disableWorkspaceResolution(
      context,
      packageConfig: packageConfig,
      packageGraph: packageGraph,
      projectDirectory: projectDirectory.path,
      workspaceRoot: workspaceRoot.path,
      exit: exit,
    );
    // Copy the pubspec.lock from the workspace root to ensure the same versions
    // of dependencies are used in the production build.
    revertPubspecLock = copyWorkspacePubspecLock(
      context,
      projectDirectory: projectDirectory.path,
      workspaceRoot: workspaceRoot.path,
      exit: exit,
    );
  }

  // We need to make sure that the pubspec.lock file is up to date.
  await dartPubGet(
    context,
    message: 'Updating lockfile',
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

  restoreWorkspaceResolution?.call();

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
    projectDirectory,
  );

  final externalDependencies = await createExternalPackagesFolder(
    projectDirectory: projectDirectory,
    buildDirectory: buildDirectory,
    copyPath: copyPath,
  );

  revertPubspecLock?.call();

  final customDockerFile = io.File(
    path.join(projectDirectory.path, 'Dockerfile'),
  );
  final addDockerfile = !customDockerFile.existsSync();

  context.vars = {
    'directories': configuration.directories.map((c) => c.toJson()).toList(),
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
