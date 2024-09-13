import 'dart:math';
import 'dart:typed_data';

import 'package:ledger_bitcoin/src/utils/merkle/merkle_node.dart';
import 'package:ledger_bitcoin/src/utils/utils.dart';

/// This class implements the merkle tree used by Ledger Bitcoin app v2+,
/// which is documented at
/// https://github.com/LedgerHQ/app-bitcoin-new/blob/master/doc/merkle.md
class Merkle {
  late List<Uint8List> _leaves;
  late MerkleNode _rootNode;
  late List<MerkleNode> _leafNodes;
  late Uint8List Function(Uint8List) _h;

  Merkle(Iterable<Uint8List> leaves,
      {Uint8List Function(Uint8List) hasher = sha256Hasher}) {
    _leaves = leaves.toList();
    _h = hasher;

    final nodes = calculateRoot(_leaves);
    _rootNode = nodes.root;
    _leafNodes = nodes.leaves;
  }

  Uint8List get root => _rootNode.hash;

  int get size => leaves.length;

  List<Uint8List> get leaves => _leaves;

  Uint8List getLeafHash(int index) => _leafNodes[index].hash;

  List<Uint8List> getProof(int index) {
    if (index >= leaves.length) throw Exception('Index out of bounds');
    return _leafNodes[index].proveNode();
  }

  MerkleTree calculateRoot(List<Uint8List> leaves) {
    final n = leaves.length;

    if (n == 0) return MerkleTree(MerkleNode(Uint8List(32)), []);

    if (n == 1) {
      final newNode = MerkleNode(leaves[0]);
      return MerkleTree(newNode, [newNode]);
    }

    final leftCount = highestPowerOf2LessThan(n);
    final leftBranch = calculateRoot(leaves.sublist(0, leftCount));
    final rightBranch = calculateRoot(leaves.sublist(leftCount));
    final leftChild = leftBranch.root;
    final rightChild = rightBranch.root;
    final hash = hashNode(leftChild.hash, rightChild.hash);
    final node = MerkleNode(hash, leftChild: leftChild, rightChild: rightChild);
    leftChild.parent = node;
    rightChild.parent = node;
    return MerkleTree(node, leftBranch.leaves..addAll(rightBranch.leaves));
  }

  Uint8List hashNode(Uint8List left, Uint8List right) {
    final bytesBuilder = BytesBuilder()
      ..add([1])
      ..add(left)
      ..add(right);

    return _h(bytesBuilder.toBytes());
  }
}

class MerkleTree {
  final MerkleNode root;
  final List<MerkleNode> leaves;

  MerkleTree(this.root, this.leaves);
}

Uint8List hashLeaf(Uint8List buf,
        {Uint8List Function(Uint8List) hashFunction = sha256Hasher}) =>
    hashConcat(Uint8List.fromList([0]), buf, hashFunction: hashFunction);

Uint8List hashConcat(Uint8List bufA, Uint8List bufB,
    {Uint8List Function(Uint8List) hashFunction = sha256Hasher}) {
  final bytesBuilder = BytesBuilder()
    ..add(bufA)
    ..add(bufB);
  return hashFunction(bytesBuilder.toBytes());
}

int highestPowerOf2LessThan(int n) {
  if (n < 2) throw Exception("Expected n >= 2");
  if (isPowerOf2(n)) return n ~/ 2;
  return 1 << log2(n).floor();
}

bool isPowerOf2(int n) => (n & (n - 1)) == 0;

double log2(num x) => log(x) / log(2);
