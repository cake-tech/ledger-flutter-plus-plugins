import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';

extension ToHexString on Uint8List {
  String toHexString() => hex.encode(this);

  String toAsciiString() => ascii.decode(this);
}
