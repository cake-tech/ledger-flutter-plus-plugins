import 'dart:typed_data';

import 'package:ledger_bitcoin/src/utils/buffer_writer.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';

class Key {
  final int keyType;
  final Uint8List keyData;

  Key(this.keyType, this.keyData);

  @override
  String toString() {
    final buf = BufferWriter();
    _toBuffer(buf);
    return buf.buffer().toHexString();
  }

  void serialize(BufferWriter buf) {
    buf.writeVarInt(1 + keyData.length);
    _toBuffer(buf);
  }

  void _toBuffer(BufferWriter buf) {
    buf.writeUInt8(keyType);
    buf.writeSlice(keyData);
  }
}

class KeyPair {
  final Key key;
  final Uint8List value;

  KeyPair(this.key, this.value);

  void serialize(BufferWriter buf) {
    key.serialize(buf);
    buf.writeVarSlice(value);
  }
}
