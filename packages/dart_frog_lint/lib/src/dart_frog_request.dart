import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_frog_lint/src/parse_route.dart';
import 'package:dart_frog_lint/src/types.dart';

/// {@template dart_frog_lint.request}
/// The definition of `dart_frog_request` lints.
/// {@endtemplate}
class DartFrogRequest extends DartLintRule {
  /// {@macro dart_frog_lint.request}
  const DartFrogRequest()
      : super(
          code: const LintCode(
            name: 'dart_frog_route',
            problemMessage:
                'Dart files within the "route" directory should define a '
                'valid "onRequest" function.',
          ),
        );

  @override
  List<String> get filesToAnalyze => ['routes/**.dart'];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // package:glob which filesToAnalyze uses does not seem to support exclude
    // patterns, so we have to manually filter out the _middleware.dart files
    // See https://github.com/dart-lang/glob/issues/75
    if (resolver.path.endsWith('_middleware.dart')) return;

    context.registry.addCompilationUnit((node) {
      // Search for a function declaration with the name "onRequest"
      final onRequest =
          node.declarations.whereType<FunctionDeclaration>().firstWhereOrNull(
                (declaration) => declaration.name.lexeme == 'onRequest',
              );

      if (onRequest == null) {
        // No function declaration found with the name "onRequest"
        reporter.reportErrorForNode(code, node.directives.firstOrNull ?? node);
        return;
      }

      final parameters = onRequest.functionExpression.parameters;
      if (parameters == null) {
        // Possible syntax error
        reporter.reportErrorForNode(code, onRequest);
        return;
      }

      final contextParameterType = onRequest.functionExpression.parameters
          ?.parameters.firstOrNull?.declaredElement?.type;
      if (contextParameterType == null ||
          !requestContextTypeChecker.isExactlyType(contextParameterType)) {
        // The onRequest function doesn't have a "RequestContext" parameter
        reporter.reportErrorForNode(code, onRequest);
        return;
      }

      if (!isOnRequestResponse(onRequest.returnType?.type)) {
        // The onRequest function doesn't return a "Response"
        reporter.reportErrorForNode(code, onRequest);
        return;
      }

      final route = parseRoute(resolver.path);
      if (onRequest.functionExpression.parameters?.parameters.length !=
          1 + route.parameters.length) {
        // The onRequest function doesn't have the correct number of parameters
        reporter.reportErrorForNode(code, onRequest);
        return;
      }

      for (final parameter in parameters.parameters.skip(1)) {
        final parameterType = parameter.declaredElement?.type;
        if (parameterType?.isDartCoreString != true) {
          // Route parameters should be positional strings
          reporter.reportErrorForNode(code, onRequest);
          return;
        }
      }
    });
  }
}
