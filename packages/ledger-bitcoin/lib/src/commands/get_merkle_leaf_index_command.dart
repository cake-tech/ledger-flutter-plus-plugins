import 'dart:typed_data';

import 'package:dart_varuint_bitcoin/dart_varuint_bitcoin.dart' as varuint;
import 'package:ledger_bitcoin/src/commands/client_command.dart';
import 'package:ledger_bitcoin/src/utils/merkle/merkle.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class GetMerkleLeafIndexCommand extends ClientCommand {
  final Map<String, Merkle> _knownTrees;

  GetMerkleLeafIndexCommand(this._knownTrees) : super();

  @override
  ClientCommandCode get code => ClientCommandCode.getMerkleLeafIndex;

  @override
  Uint8List execute(Uint8List request) {
    final req = request.sublist(1);

    if (req.length != 32 + 32) {
      throw Exception("Invalid request, unexpected trailing data");
    }

    // read the root hash
    final rootHash = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      rootHash[i] = req[i];
    }
    final rootHashHex = rootHash.toHexString();

    // read the leaf hash
    final leefHash = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      leefHash[i] = req[32 + i];
    }
    final leefHashHex = leefHash.toHexString();

    final mt = _knownTrees[rootHashHex];
    if (mt == null) {
      throw Exception('Requested Merkle leaf index for unknown root: $rootHashHex');
    }

    var leafIndex = 0;
    var found = 0;
    for (var i = 0; i < mt.size; i++) {
      if (mt.getLeafHash(i).toHexString() == leefHashHex) {
        found = 1;
        leafIndex = i;
        break;
      }
    }

    final writer = ByteDataWriter()
      ..writeUint8(found)
      ..write(varuint.encode(leafIndex).buffer);

    return writer.toBytes();
  }
}
