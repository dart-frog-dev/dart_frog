import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_frog_cli/src/command.dart';
import 'package:dart_frog_cli/src/commands/commands.dart';
import 'package:dart_frog_cli/src/commands/new/templates/dart_frog_new_bundle.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// {@template new_command}
/// `dart_frog new <route|middleware> "path/to/route"`
///
/// Creates a new route or middleware for dart_frog.
/// {@endtemplate}
class NewCommand extends DartFrogCommand {
  /// {@macro new_command}
  NewCommand({super.logger, GeneratorBuilder? generator})
    : _generator = generator ?? MasonGenerator.fromBundle {
    addSubcommand(newRouteCommand = _NewSubCommand('route'));
    addSubcommand(newMiddlewareCommand = _NewSubCommand('middleware'));
  }

  final GeneratorBuilder _generator;

  @override
  String get description => 'Create a new route or middleware for dart_frog';

  @override
  String get name => 'new';

  @override
  late final String invocation =
      'dart_frog new <${subcommands.keys.join('|')}> "path/to/route"';

  /// Subcommand for creating a new route.
  @visibleForTesting
  late final DartFrogCommand newRouteCommand;

  /// Subcommand for creating a new middleware.
  @visibleForTesting
  late final DartFrogCommand newMiddlewareCommand;
}

class _NewSubCommand extends DartFrogCommand {
  _NewSubCommand(this.name);

  @override
  String get description => 'Create a new $name for dart_frog';

  @override
  final String name;

  @override
  NewCommand get parent => super.parent! as NewCommand;

  @override
  late final String invocation = 'dart_frog new $name "path/to/route"';

  @visibleForTesting
  @override
  // ignore: invalid_use_of_visible_for_testing_member
  ArgResults? get testArgResults => parent.testArgResults;

  @override
  // ignore: invalid_use_of_visible_for_testing_member
  String? get testUsage => parent.testUsage;

  String get _routePath {
    final rest = results.rest;
    if (rest.isEmpty) {
      throw UsageException(
        'Provide a route path for the new $name',
        usageString,
      );
    }
    final routeName = rest.first;
    if (routeName.isEmpty) {
      throw UsageException('Route path must not be empty', usageString);
    }

    final segments = routeName
        .split('/')
        .skipWhile((element) => element.isEmpty);

    for (final segment in segments) {
      if (segment.isEmpty) {
        throw UsageException('Route path cannot contain empty segments', '');
      }
      if (segment.contains(RegExp(r'[^a-zA-Z\d_\[\]]'))) {
        throw UsageException(
          'Route path segments must be valid Dart identifiers',
          '',
        );
      }
    }

    return routeName;
  }

  @override
  Future<int> run() async {
    final routePath = _routePath;

    final generator = await parent._generator(dartFrogNewBundle);

    final vars = <String, dynamic>{'route_path': routePath, 'type': name};

    final routesDirectory = Directory(path.join(cwd.path, 'routes'));
    if (!routesDirectory.existsSync()) {
      throw UsageException(
        'No "routes" directory found in the current directory. '
        'Make sure to run this command on a dart_frog project.',
        usageString,
      );
    }

    await generator.hooks.preGen(
      vars: vars,
      workingDirectory: cwd.path,
      onVarsChanged: vars.addAll,
      logger: logger,
    );

    if (!vars.containsKey('dir_path')) {
      return ExitCode.software.code;
    }

    final generateProgress = logger.progress('Creating $name $routePath');

    await generator.generate(DirectoryGeneratorTarget(cwd), vars: vars);

    await generator.hooks.postGen(
      vars: vars,
      workingDirectory: cwd.path,
      logger: logger,
    );
    generateProgress.complete();

    return ExitCode.success.code;
  }
}
