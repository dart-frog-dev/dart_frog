import 'dart:io' as io;

import 'package:dart_frog_gen/dart_frog_gen.dart';
import 'package:dart_frog_new_hooks/src/exit_overrides.dart';
import 'package:dart_frog_new_hooks/src/normalize_route_path.dart';
import 'package:dart_frog_new_hooks/src/parameter_syntax.dart';
import 'package:dart_frog_new_hooks/src/route_configuration_utils.dart';
import 'package:dart_frog_new_hooks/src/route_to_path.dart';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

typedef RouteConfigurationBuilder = RouteConfiguration Function(
  io.Directory directory,
);

void _defaultExit(int code) => ExitOverrides.current?.exit ?? io.exit;

void preGen(
  HookContext context, {
  io.Directory? directory,
  RouteConfigurationBuilder buildConfiguration = buildRouteConfiguration,
  void Function(int exitCode) exit = _defaultExit,
}) {
  // The dart frog server project directory
  final projectDirectory = directory ?? io.Directory.current;

  // Build the route configuration
  final RouteConfiguration routeConfiguration;
  try {
    routeConfiguration = buildConfiguration(projectDirectory);
  } on Exception catch (error) {
    context.logger.err('$error');
    return exit(1);
  }

  // Get the desired type of creation
  final type = context.vars['type'] as String;

  // Verify if current route configuration have conflicts and bail out if
  // any are found
  try {
    routeConfiguration.validate();
  } on FormatException catch (exception) {
    context.logger.err('Failed to create $type: ${exception.message}');
    return exit(1);
  }

  // The path in which the route or middleware will be created
  final routePath = normalizeRoutePath(context.vars['route_path'] as String);

  if (type == 'route') {
    return _preGenRoute(
      context,
      routePath: routePath,
      routeConfiguration: routeConfiguration,
      projectDirectory: projectDirectory,
      exit: exit,
    );
  }

  if (type == 'middleware') {
    return _preGenMiddleware(
      context,
      routePath: routePath,
      routeConfiguration: routeConfiguration,
      projectDirectory: projectDirectory,
      exit: exit,
    );
  }

  context.logger.err('Unrecognized type: $type');
  return exit(1);
}

void _preGenRoute(
  HookContext context, {
  required String routePath,
  required RouteConfiguration routeConfiguration,
  required io.Directory projectDirectory,
  required void Function(int exitCode) exit,
}) {
  final routesDirectoryPath = path.relative(
    io.Directory(path.join(projectDirectory.path, 'routes')).path,
  );

  // Verify if the endpoint does already exist.
  final endpointExists = routeConfiguration.endpoints.containsKey(routePath);
  if (endpointExists) {
    context.logger.err('Failed to create route: $routePath already exists.');
    return exit(1);
  }

  // Verify if the given route already exists as directory.
  final existsAsDirectory = io.Directory(
    path.withoutExtension(
      routeToPath(
        routePath,
        preamble: routesDirectoryPath,
      ).toBracketParameterSyntax,
    ),
  ).existsSync();

  // If the route does not exist as directory, we must check if any of its
  // ancestor routes exists as file routes to avoid rogue routes.
  if (!existsAsDirectory) {
    final fileRoute = routeConfiguration.containingFileRoute(routePath);

    if (fileRoute != null) {
      final filepath = path.normalize(
        path.join(
          routesDirectoryPath,
          fileRoute.path,
        ),
      );

      io.Directory(path.withoutExtension(filepath)).createSync();

      final newFilepath = filepath.replaceFirst('.dart', '/index.dart');
      io.File(filepath).renameSync(newFilepath);
      context.logger.detail(
        'Renamed $filepath to $newFilepath to avoid rogue routes',
      );
    }
  }

  final routeFileName = routeToPath(
    routePath,
    preferIndex: existsAsDirectory,
    preamble: routesDirectoryPath,
  ).toBracketParameterSyntax;

  context.logger.detail('Creating route file: $routeFileName');

  final List<String> parameterNames;
  try {
    parameterNames = routeFileName.getParameterNames();
  } on FormatException catch (exception) {
    context.logger.err('Failed to create route: ${exception.message}');
    return exit(1);
  }

  context.vars['is_route'] = true;
  context.vars['dir_path'] = path.dirname(routeFileName);
  context.vars['filename'] = path.basename(routeFileName);
  context.vars['params'] = parameterNames;
}

void _preGenMiddleware(
  HookContext context, {
  required String routePath,
  required RouteConfiguration routeConfiguration,
  required io.Directory projectDirectory,
  required void Function(int exitCode) exit,
}) {
  final routesDirectoryPath = path.relative(
    io.Directory(path.join(projectDirectory.path, 'routes')).path,
  );

  const middlewareFilename = '_middleware.dart';

  final createsMiddlewareOfMiddleware = routePath
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .contains('_middleware');
  if (createsMiddlewareOfMiddleware) {
    context.logger.err('Cannot create middleware inside another middleware.');
    return exit(1);
  }

  // Get the path to directory containing the middleware file
  final String middlewareContainingDir;
  if (routePath == '/') {
    middlewareContainingDir = routesDirectoryPath;
  } else {
    middlewareContainingDir = path.withoutExtension(
      routeToPath(
        routePath.toBracketParameterSyntax,
        preamble: routesDirectoryPath,
      ),
    );
  }

  // Verify if the middleware file already exists
  final middlewareFilePath =
      path.join(middlewareContainingDir, middlewareFilename);
  final middlewareExists = io.File(middlewareFilePath).existsSync();
  if (middlewareExists) {
    context.logger.err('There is already a middleware at $middlewareFilePath');
    return exit(1);
  }

  // Verify if the given route already exists as directory
  final routeExistsAsDirectory = io.Directory(
    middlewareContainingDir.toBracketParameterSyntax,
  ).existsSync();

  // If the route does not exist as directory, we must check if any of its
  // ancestor routes exists as file routes to avoid rogue routes.
  if (!routeExistsAsDirectory) {
    final fileRoute = routeConfiguration.containingFileRoute(
      routePath,
      includeSelf: true,
    );

    if (fileRoute != null) {
      final filePath = path.normalize(
        path.join(routesDirectoryPath, fileRoute.path),
      );

      io.Directory(path.withoutExtension(filePath)).createSync();

      final newFilepath = filePath.replaceFirst('.dart', '/index.dart');
      io.File(filePath).renameSync(newFilepath);
      context.logger
          .detail('Renamed $filePath to $newFilepath to avoid rogue routes');
    }
  }

  try {
    middlewareContainingDir.toBracketParameterSyntax.getParameterNames();
  } on FormatException catch (exception) {
    context.logger.err('Failed to create middleware: ${exception.message}');
    return exit(1);
  }

  context.logger.detail(
    'Creating middleware file: ${middlewareFilePath.toBracketParameterSyntax}',
  );

  context.vars['is_middleware'] = true;
  context.vars['dir_path'] = middlewareContainingDir.toBracketParameterSyntax;
  context.vars['filename'] = middlewareFilename;
}
