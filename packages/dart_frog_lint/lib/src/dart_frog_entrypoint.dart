import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_frog_lint/src/types.dart';

/// {@template dart_frog_lint.request}
/// The definition of `dart_frog_entrypoint` lints.
/// {@endtemplate}
class DartFrogEntrypoint extends DartLintRule {
  /// {@macro dart_frog_lint.request}
  const DartFrogEntrypoint()
      : super(
          code: const LintCode(
            name: 'dart_frog_entrypoint',
            problemMessage: 'Main files should define a valid "run" function.',
          ),
        );

  @override
  List<String> get filesToAnalyze => ['main.dart'];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      // Search for a function declaration with the name "run"
      final run =
          node.declarations.whereType<FunctionDeclaration>().firstWhereOrNull(
                (declaration) => declaration.name.lexeme == 'run',
              );

      if (run == null) {
        // No function declaration found with the name "run"
        reporter.reportErrorForNode(code, node.directives.firstOrNull ?? node);
        return;
      }

      if (run.functionExpression.parameters?.parameters.length != 3) {
        // Only three parameters are allowed
        reporter.reportErrorForNode(code, run);
        return;
      }

      final handlerType = run.functionExpression.parameters?.parameters
          .firstOrNull?.declaredElement?.type;
      final ipType = run.functionExpression.parameters?.parameters
          .elementAtOrNull(1)
          ?.declaredElement
          ?.type;
      final portType = run.functionExpression.parameters?.parameters
          .elementAtOrNull(2)
          ?.declaredElement
          ?.type;

      if (handlerType == null || !isHandler(handlerType)) {
        // The parameter is not a Handler
        reporter.reportErrorForNode(code, run);
        return;
      }

      if (ipType == null || !isInternetAddress(ipType)) {
        // The parameter is not an InternetAddress
        reporter.reportErrorForNode(code, run);
        return;
      }

      if (portType?.isDartCoreInt != true) {
        // The parameter is not a int
        reporter.reportErrorForNode(code, run);
        return;
      }

      final returnType = run.returnType?.type;
      if (returnType == null ||
          !returnType.isDartAsyncFuture ||
          !isHttpServer(
            (returnType as InterfaceType).typeArguments.single,
          )) {
        // The parameter is not a HttpServer
        reporter.reportErrorForNode(code, run);
        return;
      }
    });
  }
}
