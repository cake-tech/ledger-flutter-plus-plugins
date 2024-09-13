import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ledger_bitcoin/src/utils/buffer_reader.dart';
import 'package:ledger_bitcoin/src/utils/buffer_writer.dart';
import 'package:ledger_bitcoin/src/utils/utils.dart';
import 'package:test/test.dart';

void run(int n, String expectedHex) {
  final w = BufferWriter()..writeUInt64(n);
  expect(w.buffer(), hex.decode(expectedHex));
  final r = BufferReader(w.buffer());
  expect(r.readUInt64(), n);
}

void main() {
  group('Utils', () {
    test("pointAddScalar (-1 + 0 == -1)", () {
      final P = hex.decode("0379be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798") as Uint8List;
      final d = hex.decode("0000000000000000000000000000000000000000000000000000000000000000") as Uint8List;

      final res = pointAddScalar(P, d);
      expect(hex.encode(res), "0379be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798");
    });

    test("pointAddScalar ", () {
      final P = hex.decode("0379be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798") as Uint8List;
      final d = hex.decode("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd036413f") as Uint8List;

      final res = pointAddScalar(P, d);
      expect(hex.encode(res), "03f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9");
    });
  });
}
