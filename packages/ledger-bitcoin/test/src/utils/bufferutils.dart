import 'package:convert/convert.dart';
import 'package:ledger_bitcoin/src/utils/buffer_reader.dart';
import 'package:ledger_bitcoin/src/utils/buffer_writer.dart';
import 'package:test/test.dart';

void run(int n, String expectedHex) {
  final w = BufferWriter()..writeUInt64(n);
  expect(w.buffer(), hex.decode(expectedHex));
  final r = BufferReader(w.buffer());
  expect(r.readUInt64(), n);
}

void main() {
  group('BufferWriter & BufferReader', () {
    test("Test 64 bit numbers", () {
      run(0, "0000000000000000");
      run(1, "0100000000000000");
      run(0xffffffff, "ffffffff00000000");
      run(0x0100000000, "0000000001000000");
      run(0x010203040506, "0605040302010000");
    });
  });
}
