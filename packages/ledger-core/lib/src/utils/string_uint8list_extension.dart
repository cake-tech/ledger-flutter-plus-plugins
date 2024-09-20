import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';

extension ToHexString on Uint8List {
  String toHexString() => hex.encode(this);

  String toPaddedHexString() =>
      map((e) => e.toRadixString(16).padLeft(2, '0')).join();

  String toAsciiString() => ascii.decode(this);
}

Uint8List fromHexString(String hexString) =>
    Uint8List.fromList(hex.decode(hexString));
