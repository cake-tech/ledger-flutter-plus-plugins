import 'dart:typed_data';

import 'package:ledger_litecoin/src/utils/string_uint8list_extension.dart';


extension ToMessageSignature on Uint8List {
  String toMessageSignature() {
    final v = this[0].toInt();
    final r = sublist(1, 1 + 32).toHexString();
    final s = sublist(1 + 32, 1 + 32 + 32).toHexString();

    return "0x$r$s${v.toRadixString(16)}";
  }
}
