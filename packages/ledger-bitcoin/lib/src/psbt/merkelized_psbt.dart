import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ledger_bitcoin/src/psbt/psbtv2.dart';
import 'package:ledger_bitcoin/src/utils/merkle/merkle_map.dart';

/// This class merkelizes a PSBTv2, by merkelizing the different
/// maps of the psbt. This is used during the transaction signing process,
/// where the hardware app can request specific parts of the psbt from the
/// client code and be sure that the response data actually belong to the psbt.
/// The reason for this is the limited amount of memory available to the app,
/// so it can't always store the full psbt in memory.
///
/// The signing process is documented at
/// https://github.com/LedgerHQ/app-bitcoin-new/blob/master/doc/bitcoin.md#sign_psbt
class MerkelizedPsbt extends PsbtV2 {
  late final MerkleMap globalMerkleMap;
  final inputMerkleMaps = <MerkleMap>[];
  final outputMerkleMaps = <MerkleMap>[];
  late final List<Uint8List> inputMapCommitments;
  late final List<Uint8List> outputMapCommitments;

  MerkelizedPsbt(PsbtV2 psbt) : super() {
    psbt.copy(this);
    globalMerkleMap = MerkelizedPsbt._createMerkleMap(globalMap);

    for (var i = 0; i < getGlobalInputCount(); i++) {
      inputMerkleMaps.add(MerkelizedPsbt._createMerkleMap(inputMaps[i]));
    }
    inputMapCommitments = inputMerkleMaps.map((v) => v.commitment).toList();

    for (var i = 0; i < getGlobalOutputCount(); i++) {
      outputMerkleMaps.add(MerkelizedPsbt._createMerkleMap(outputMaps[i]));
    }
    outputMapCommitments = outputMerkleMaps.map((v) => v.commitment).toList();
  }

  int get globalSize => globalMap.length;

  Uint8List get globalKeysValuesRoot => globalMerkleMap.commitment;

  static MerkleMap _createMerkleMap(Map<String, Uint8List> map) {
    final sortedKeysStrings = map.keys.toList()..sort();
    final values = sortedKeysStrings.map((k) => map[k]!);
    final sortedKeys =
        sortedKeysStrings.map((k) => Uint8List.fromList(hex.decode(k)));

    return MerkleMap(sortedKeys, values);
  }
}
