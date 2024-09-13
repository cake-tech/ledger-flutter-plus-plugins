import 'dart:math';
import 'dart:typed_data';

import 'package:ledger_bitcoin/src/commands/client_command.dart';
import 'package:ledger_bitcoin/src/utils/int_extension.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class GetPreimageCommand extends ClientCommand {
  final Map<String, Uint8List> _knownPreimages;
  final List<Uint8List> _queue;

  @override
  ClientCommandCode get code => ClientCommandCode.getPreimage;

  GetPreimageCommand(this._knownPreimages, this._queue) : super();

  @override
  Uint8List execute(Uint8List request) {
    final req = request.sublist(1);

    // we expect no more data to read
    if (req.length != 1 + 32) {
      throw Exception("Invalid request, unexpected trailing data");
    }

    if (req[0] != 0) {
      throw Exception("Unsupported request, the first byte should be 0");
    }

    // read the hash
    final hash = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      hash[i] = req[1 + i];
    }

    final reqHashHex = hash.toHexString();
    final knownPreimage = _knownPreimages[reqHashHex];
    if (knownPreimage != null) {
      final preimageLenVarint = knownPreimage.length.toVarint();

      // We can send at most 255 - len(preimage_len_out) - 1 bytes in a single message;
      // the rest will be stored in the queue for GET_MORE_ELEMENTS
      final maxPayloadSize = 255 - preimageLenVarint.length - 1;
      final payloadSize = min(maxPayloadSize, knownPreimage.length);

      if (payloadSize < knownPreimage.length) {
        for (var i = payloadSize; i < knownPreimage.length; i++) {
          _queue.add(Uint8List.fromList([knownPreimage[i]]));
        }
      }

      final writer = ByteDataWriter()
        ..write(preimageLenVarint)
        ..writeUint8(payloadSize)
        ..write(knownPreimage.sublist(0, payloadSize));

      return writer.toBytes();
    }

    throw Exception('Requested unknown preimage for: $reqHashHex');
  }
}
