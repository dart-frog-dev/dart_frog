import 'package:dart_frog_prod_server_hooks/dart_frog_prod_server_hooks.dart';

PackageGraph? getPackageGraph(String workspaceRoot) {
  try {
    return PackageGraph.load(workspaceRoot);
  } on Exception {
    return null;
  }
}
