import 'dart:typed_data';

import 'package:ledger_bitcoin/src/commands/client_command.dart';

class YieldCommand extends ClientCommand {
  final List<Uint8List> _results;
  final void Function() _progressCallback;

  @override
  ClientCommandCode get code => ClientCommandCode.yield;

  YieldCommand(this._results, this._progressCallback);

  @override
  Uint8List execute(Uint8List request) {
    _results.add(request.sublist(1));
    _progressCallback();
    return Uint8List(0);
  }
}
