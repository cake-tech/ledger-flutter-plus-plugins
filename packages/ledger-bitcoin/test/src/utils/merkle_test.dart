import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ledger_bitcoin/src/utils/merkle/merkle.dart';
import 'package:test/test.dart';

Uint8List testHasher(Uint8List buf) => Uint8List.fromList(buf);

Uint8List leaf(int n) => Uint8List.fromList([0, n]);

Merkle merkleOf(int count) {
  final leaves = <Uint8List>[];
  for (var i = 0; i < count; i++) {
    leaves.add(leaf(i));
  }
  return Merkle(leaves, hasher: testHasher);
}

Uint8List rootOfLeaves(Iterable<int> leaves) =>
    Merkle(leaves.map((v) => leaf(v)), hasher: testHasher).root;

Uint8List rootOf(int count) {
  final manuals = [
    "0000000000000000000000000000000000000000000000000000000000000000",
    "0000",
    "0100000001",
    "0101000000010002",
    "0101000000010100020003",
    "0101010000000101000200030004",
  ];
  return Uint8List.fromList(hex.decode(manuals[count]));
}

void main() {
  group('Merkle', () {
    test("Merkle root of N", () {
      for (var i = 1; i <= 5; i++) {
        final root = merkleOf(i).root;
        final expectedRoot = rootOf(i);
        expect(root, expectedRoot);
      }
    });

    test("Merkle proof of single", () {
      final proof = merkleOf(1).getProof(0);
      expect(proof, []);
    });

    test("Merkle proof of two", () {
      expect(merkleOf(2).getProof(0), [
        rootOfLeaves([1])
      ]);
      expect(merkleOf(2).getProof(1), [
        rootOfLeaves([0])
      ]);
    });

    test("Merkle proof of three", () {
      expect(merkleOf(3).getProof(0), [
        rootOfLeaves([1]),
        rootOfLeaves([2])
      ]);
      expect(merkleOf(3).getProof(1), [
        rootOfLeaves([0]),
        rootOfLeaves([2])
      ]);
      expect(merkleOf(3).getProof(2), [
        rootOfLeaves([0, 1])
      ]);
    });

    test("Merkle proof of four", () {
      expect(merkleOf(4).getProof(0), [
        rootOfLeaves([1]),
        rootOfLeaves([2, 3])
      ]);
      expect(merkleOf(4).getProof(1), [
        rootOfLeaves([0]),
        rootOfLeaves([2, 3])
      ]);
      expect(merkleOf(4).getProof(2), [
        rootOfLeaves([3]),
        rootOfLeaves([0, 1])
      ]);
      expect(merkleOf(4).getProof(3), [
        rootOfLeaves([2]),
        rootOfLeaves([0, 1])
      ]);
    });

    test("Merkle proof of five", () {
      expect(merkleOf(5).getProof(0), [
        rootOfLeaves([1]),
        rootOfLeaves([2, 3]),
        rootOfLeaves([4])
      ]);
      expect(merkleOf(5).getProof(1), [
        rootOfLeaves([0]),
        rootOfLeaves([2, 3]),
        rootOfLeaves([4])
      ]);
      expect(merkleOf(5).getProof(2), [
        rootOfLeaves([3]),
        rootOfLeaves([0, 1]),
        rootOfLeaves([4])
      ]);
      expect(merkleOf(5).getProof(3), [
        rootOfLeaves([2]),
        rootOfLeaves([0, 1]),
        rootOfLeaves([4])
      ]);
      expect(merkleOf(5).getProof(4), [
        rootOfLeaves([0, 1, 2, 3])
      ]);
    });
  });
}
