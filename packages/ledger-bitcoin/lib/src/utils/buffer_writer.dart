import 'dart:typed_data';

import 'package:dart_varuint_bitcoin/dart_varuint_bitcoin.dart' as varuint;
import 'package:ledger_bitcoin/src/utils/int_extension.dart';

class BufferWriter {
  final _buffers = <Uint8List>[];

  void writeUInt8(int i) => _buffers.add(i.toUint8());

  void writeInt32(int i) => _buffers.add(i.toInt32LE());

  void writeUInt32(int i) => _buffers.add(i.toUint32LE());

  void writeUInt64(int i) => _buffers.add(i.toUint64LE());

  void writeVarInt(int i) => _buffers.add(varuint.encode(i).buffer);

  void writeSlice(Uint8List slice) => _buffers.add(slice);

  void writeVarSlice(Uint8List slice) {
    writeVarInt(slice.length);
    writeSlice(slice);
  }

  Uint8List buffer() {
    final bytesBuilder = BytesBuilder();
    for (var element in _buffers) {
      bytesBuilder.add(element);
    }
    return bytesBuilder.toBytes();
  }
}
