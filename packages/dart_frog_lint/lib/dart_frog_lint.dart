import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_frog_lint/src/dart_frog_entrypoint.dart';
import 'package:dart_frog_lint/src/dart_frog_middleware.dart';
import 'package:dart_frog_lint/src/dart_frog_request.dart';

/// The entrypoint of dart_frog_lint
PluginBase createPlugin() => _DartFrogLintPlugin();

class _DartFrogLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const DartFrogRequest(),
        const DartFrogMiddleware(),
        const DartFrogEntrypoint(),
      ];
}
