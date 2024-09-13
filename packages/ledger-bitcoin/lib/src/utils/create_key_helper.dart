import 'dart:typed_data';

import 'package:ledger_bitcoin/src/utils/bip32_path.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';

String createKey(Uint8List masterFingerprint, List<int> path, String xPub) {
  final accountPath = BIPPath.fromPathArray(path).toString();
  return '[${masterFingerprint.toHexString()}${accountPath.substring(1)}]$xPub/**';
}

