import 'dart:typed_data';

import 'package:ledger_bitcoin/src/utils/int_extension.dart';
import 'package:ledger_bitcoin/src/utils/iterable_extension.dart';
import 'package:ledger_bitcoin/src/utils/merkle/merkle.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';

/// This implements "Merkelized Maps", documented at
/// https://github.com/LedgerHQ/app-bitcoin-new/blob/master/doc/merkle.md#merkleized-maps
///
/// A merkelized map consist of two merkle trees, one for the keys of
/// a map and one for the values of the same map, thus the two merkle
/// trees have the same shape. The commitment is the number elements
/// in the map followed by the keys' merkle root followed by the
/// values' merkle root.
class MerkleMap {
  final Iterable<Uint8List> keys;
  late final Merkle keysTree;
  final Iterable<Uint8List> values;
  late final Merkle valuesTree;

  /// [keys] Sorted list of (unhashed) keys
  /// [values] values, in corresponding order as the keys, and of equal length
  MerkleMap(this.keys, this.values) {
    if (keys.length != values.length) {
      throw Exception("keys and values should have the same length");
    }

    // Sanity check: verify that keys are actually sorted and with no duplicates
    if (!keys.isSorted<Uint8List>(
        (a, b) => a.toHexString().compareTo(b.toHexString()))) {
      throw Exception("keys must be in strictly increasing order");
    }

    keysTree = Merkle(keys.map((k) => hashLeaf(k)));
    valuesTree = Merkle(values.map((v) => hashLeaf(v)));
  }

  // returns a buffer between 65 and 73 (included) bytes long
  Uint8List get commitment {
    final bytesBuilder = BytesBuilder()
      ..add(keys.length.toVarint())
      ..add(keysTree.root)
      ..add(valuesTree.root);
    return bytesBuilder.toBytes();
  }
}
