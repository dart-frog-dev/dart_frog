import 'dart:async';

void Function() overridePrint(void Function(List<String>) fn) {
  final printLogs = <String>[];

  return () {
    final spec = ZoneSpecification(
      print: (_, _, _, String msg) {
        printLogs.add(msg);
      },
    );
    return Zone.current
        .fork(specification: spec)
        .run<void>(() => fn(printLogs));
  };
}
