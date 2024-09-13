import 'dart:typed_data';

import 'package:ledger_bitcoin/src/utils/int_extension.dart';
import 'package:test/test.dart';


void main() {
  group('int extension', () {
    test("toVarint", () {
      expect(100.toVarint(), Uint8List.fromList([100]));
      expect(100000.toVarint(), Uint8List.fromList([254, 160, 134, 1, 0]));
      expect(100000000.toVarint(), Uint8List.fromList([254, 0, 225, 245, 5]));
    });

    test("intFromVarint", () {
      expect(intFromVarint(Uint8List.fromList([100])), 100);
      expect(intFromVarint(Uint8List.fromList([254, 160, 134, 1, 0])), 100000);
      expect(intFromVarint(Uint8List.fromList([254, 0, 225, 245, 5])), 100000000);
    });

    test("toUint8", () {
      expect(0.toUint8(), Uint8List.fromList([0]));
      expect(100.toUint8(), Uint8List.fromList([100]));
      expect(255.toUint8(), Uint8List.fromList([255]));
    });

    test("toInt32LE", () {
      expect(100.toInt32LE(), Uint8List.fromList([100, 0, 0, 0]));
      expect(100000.toInt32LE(), Uint8List.fromList([160, 134, 1, 0]));
      expect(100000000.toInt32LE(), Uint8List.fromList([0, 225, 245, 5]));
      expect((-100000000).toInt32LE(), Uint8List.fromList([0, 31, 10, 250]));
    });

    test("toUint32LE", () {
      expect(100.toUint32LE(), Uint8List.fromList([100, 0, 0, 0]));
      expect(100000.toUint32LE(), Uint8List.fromList([160, 134, 1, 0]));
      expect(100000000.toUint32LE(), Uint8List.fromList([0, 225, 245, 5]));
    });

    test("toUint64LE", () {
      expect(100.toUint64LE(), Uint8List.fromList([100, 0, 0, 0, 0, 0, 0, 0]));
      expect(100000.toUint64LE(), Uint8List.fromList([160, 134, 1, 0, 0, 0, 0, 0]));
      expect(100000000.toUint64LE(), Uint8List.fromList([0, 225, 245, 5, 0, 0, 0, 0]));
    });

    test("bigIntToUint64LE", () {
      expect(bigIntToUint64LE(BigInt.from(100)), Uint8List.fromList([100, 0, 0, 0, 0, 0, 0, 0]));
      expect(bigIntToUint64LE(BigInt.from(10000000)), Uint8List.fromList([128, 150, 152, 0, 0, 0, 0, 0]));
    });
  });
}
