import 'dart:math';
import 'dart:typed_data';

import 'package:dart_varuint_bitcoin/dart_varuint_bitcoin.dart' as varuint;
import 'package:ledger_bitcoin/src/commands/client_command.dart';
import 'package:ledger_bitcoin/src/utils/merkle/merkle.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class GetMerkleLeafProofCommand extends ClientCommand {
  final Map<String, Merkle> _knownTrees;
  final List<Uint8List> _queue;

  @override
  ClientCommandCode get code => ClientCommandCode.getMerkleLeafProof;

  GetMerkleLeafProofCommand(this._knownTrees, this._queue) : super();

  @override
  Uint8List execute(Uint8List request) {
    final req = request.sublist(1);

    if (req.length < 32 + 1 + 1) {
      throw Exception("Invalid request, expected at least 34 bytes");
    }

    final hash = req.sublist(0, 32);
    final hashHex = hash.toHexString();

    int treeSize;
    int leafIndex;
    try {
      final treeSizeParsed = varuint.decode(req, 32);
      final leafIndexParsed = varuint.decode(req, 32 + treeSizeParsed.bytes);

      treeSize = treeSizeParsed.output;
      leafIndex = leafIndexParsed.output;
    } catch (e) {
      throw Exception("Invalid request, couldn't parse tree_size or leaf_index");
    }

    final mt = _knownTrees[hashHex];
    if (mt == null) {
      throw Exception('Requested Merkle leaf proof for unknown tree: $hashHex');
    }

    if (leafIndex >= treeSize || mt.size != treeSize) {
      throw Exception("Invalid index or tree size.");
    }

    if (_queue.isNotEmpty) {
      throw Exception("This command should not execute when the queue is not empty.");
    }

    final proof = mt.getProof(leafIndex);
    final nResponseElements = min(((255 - 32 - 1 - 1) / 32).floor(), proof.length);
    final nLeftoverElements = proof.length - nResponseElements;

    // Add to the queue any proof elements that do not fit the response
    if (nLeftoverElements > 0) {
      _queue.addAll(proof.sublist(proof.length - nLeftoverElements));
    }

    final writer = ByteDataWriter()
      ..write(mt.getLeafHash(leafIndex))
      ..writeUint8(proof.length)
      ..writeUint8(nResponseElements);
    proof.sublist(0, nResponseElements).forEach((element) {
      writer.write(element);
    });

    return writer.toBytes();
  }
}
