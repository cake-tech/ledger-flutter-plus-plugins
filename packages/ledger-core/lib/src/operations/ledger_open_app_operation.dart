import 'dart:convert';
import 'dart:typed_data';

import 'package:ledger_core/src/ledger_core_exceptions.dart';
import 'package:ledger_core/src/utils/string_uint8list_extension.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_core/src/ledger/core_instructions.dart';

/// This command opens a specific application on the ledger device
class LedgerOpenAppOperation extends LedgerOperation<bool> {
  final String appName;

  LedgerOpenAppOperation(this.appName);

  @override
  Future<bool> read(ByteDataReader reader) async {
    if (reader.remainingLength == 0) return true;
    final statusCode = reader.read(reader.remainingLength);

    switch (statusCode.toPaddedHexString().toLowerCase()) {
      case '6d00':
        throw LedgerAppAlreadyOpenException();
      case '6807':
        throw LedgerAppNotInstalledException();
      default:
        throw LedgerCoreException(statusCode: statusCode.toPaddedHexString());
    }
  }

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer
      ..writeUint8(coreCLA)
      ..writeUint8(openAppINS)
      ..writeUint8(0x00)
      ..writeUint8(0x00)
      ..writeUint8(ascii.encode(appName).length)
      ..write(ascii.encode(appName));

    return [writer.toBytes()];
  }
}
