import 'dart:math';
import 'dart:typed_data';

import 'package:ledger_bitcoin/src/commands/client_command.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class GetMoreElementsCommand extends ClientCommand {
  final List<Uint8List> _queue;

  GetMoreElementsCommand(this._queue) : super();

  @override
  ClientCommandCode get code => ClientCommandCode.getMoreElements;

  @override
  Uint8List execute(Uint8List request) {
    if (request.length != 1) {
      throw Exception("Invalid request, unexpected trailing data");
    }

    if (_queue.isEmpty) {
      throw Exception("No elements to get");
    }

    // all elements should have the same length
    final elementLen = _queue[0].length;
    if (_queue.any((el) => el.length != elementLen)) {
      throw Exception(
          "The queue contains elements with different byte length, which is not expected");
    }

    final maxElements = (253 / elementLen).floor();
    final nReturnedElements = min(maxElements, _queue.length);
    final returnedElements = _queue.splice(0, nReturnedElements);

    final writer = ByteDataWriter()
      ..writeUint8(nReturnedElements)
      ..writeUint8(elementLen);

    for (final element in returnedElements) {
      writer.write(element);
    }

    return writer.toBytes();
  }
}

extension _Splice<T> on List<T> {
  Iterable<T> splice(int start, int count, [List<T>? insert]) {
    final result = [...getRange(start, start + count)];
    replaceRange(start, start + count, insert ?? []);
    return result;
  }
}
