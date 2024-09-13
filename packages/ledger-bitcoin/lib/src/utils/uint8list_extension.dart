import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';

extension ToHexString on Uint8List {
  String toHexString() => hex.encode(this);

  String toAsciiString() => ascii.decode(this);

  int readUint32LE(int offset) =>
      ByteData.view(buffer).getUint32(offset, Endian.little);

  int readUint64LE(int offset) =>
      ByteData.view(buffer).getUint64(offset, Endian.little);
}

Uint8List joinUint8Lists(Iterable<Uint8List> values) {
  final bytesBuilder = BytesBuilder();
  for (final value in values) {
    bytesBuilder.add(value);
  }
  return bytesBuilder.toBytes();
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
