import 'dart:async';
import 'dart:io' as io;

const _asyncRunZoned = runZoned;

void defaultExit(int code) => ExitOverrides.current?.exit ?? io.exit;

abstract class ExitOverrides {
  static final _token = Object();

  static ExitOverrides? get current {
    return Zone.current[_token] as ExitOverrides?;
  }

  static R runZoned<R>(R Function() body, {void Function(int)? exit}) {
    final overrides = _ExitOverridesScope(exit);
    return _asyncRunZoned(body, zoneValues: {_token: overrides});
  }

  void Function(int exitCode) get exit => io.exit;
}

class _ExitOverridesScope extends ExitOverrides {
  _ExitOverridesScope(this._exit);

  final ExitOverrides? _previous = ExitOverrides.current;
  final void Function(int exitCode)? _exit;

  @override
  void Function(int exitCode) get exit {
    return _exit ?? _previous?.exit ?? super.exit;
  }
}
