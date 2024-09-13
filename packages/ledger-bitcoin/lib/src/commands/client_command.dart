import 'dart:typed_data';

enum ClientCommandCode {
  yield(0x10),
  getPreimage(0x40),
  getMerkleLeafProof(0x41),
  getMerkleLeafIndex(0x42),
  getMoreElements(0xa0);

  const ClientCommandCode(this.value);

  final int value;

  static ClientCommandCode fromInt(int val) {
    for (final ccc in ClientCommandCode.values) {
      if (val == ccc.value) return ccc;
    }
    throw Exception(
        "Unknown ClientCommandCode value 0x${val.toRadixString(16)}");
  }
}

abstract class ClientCommand {
  ClientCommandCode get code;

  Uint8List execute(Uint8List request);
}
