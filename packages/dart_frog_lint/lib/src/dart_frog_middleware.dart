import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_frog_lint/src/types.dart';

/// {@template dart_frog_lint.request}
/// The definition of `dart_frog_middleware` lints.
/// {@endtemplate}
class DartFrogMiddleware extends DartLintRule {
  /// {@macro dart_frog_lint.request}
  const DartFrogMiddleware()
      : super(
          code: const LintCode(
            name: 'dart_frog_middleware',
            problemMessage:
                'Middleware files should define a valid "middleware" function.',
          ),
        );

  @override
  List<String> get filesToAnalyze => ['routes/**_middleware.dart'];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      // Search for a function declaration with the name "middleware"
      final middleware =
          node.declarations.whereType<FunctionDeclaration>().firstWhereOrNull(
                (declaration) => declaration.name.lexeme == 'middleware',
              );

      if (middleware == null) {
        // No function declaration found with the name "middleware"
        reporter.reportErrorForNode(code, node.directives.firstOrNull ?? node);
        return;
      }

      if (middleware.functionExpression.parameters?.parameters.length != 1) {
        // Only one parameter is allowed
        reporter.reportErrorForNode(code, middleware);
        return;
      }

      final handlerType = middleware.functionExpression.parameters?.parameters
          .firstOrNull?.declaredElement?.type;
      if (handlerType == null || !isHandler(handlerType)) {
        // The parameter is not a Handler
        reporter.reportErrorForNode(code, middleware);
        return;
      }

      final returnType = middleware.returnType?.type;
      if (returnType == null || !isHandler(returnType)) {
        // The parameter is not a Handler
        reporter.reportErrorForNode(code, middleware);
        return;
      }
    });
  }
}
