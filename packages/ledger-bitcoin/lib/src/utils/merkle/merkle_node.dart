import 'dart:typed_data';

class MerkleNode {
  MerkleNode? leftChild;
  MerkleNode? rightChild;
  MerkleNode? parent;
  final Uint8List hash;

  MerkleNode(this.hash, {this.leftChild, this.rightChild});

  bool get isLeaf => leftChild == null;

  List<Uint8List> proveNode() {
    if (parent == null) return [];

    if (parent!.leftChild == this) {
      if (parent!.rightChild == null) {
        throw Exception('Expected right child to exist');
      }
      return [parent!.rightChild!.hash, ...parent!.proveNode()];
    } else {
      if (parent!.leftChild == null) {
        throw Exception('Expected left child to exist');
      }
      return [parent!.leftChild!.hash, ...parent!.proveNode()];
    }
  }
}
