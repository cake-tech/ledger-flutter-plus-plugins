import 'dart:typed_data';

import 'package:convert/convert.dart';

extension ToInt on Uint8List {
  int toInt() => int.parse(hex.encode(this), radix: 16);
}
