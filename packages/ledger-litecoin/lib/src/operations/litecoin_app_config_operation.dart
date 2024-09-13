import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/firmware_version.dart';
import 'package:ledger_litecoin/src/ledger/litecoin_instructions.dart';

/// This command returns specific application configuration
class LitecoinAppConfigOperation extends LedgerOperation<FirmwareVersion> {
  @override
  Future<FirmwareVersion> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);

    var i = 0;
    final flags = response[i++];
    final architecture = response[i++];
    final majorVersion = response[i++];
    final minorVersion = response[i++];
    final patchVersion = response[i++];

    return FirmwareVersion(
        majorVersion, minorVersion, patchVersion, flags, architecture);
  }

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer
      ..writeUint8(btcCLA)
      ..writeUint8(getFirmwareVersionINS)
      ..writeUint8(0x00)
      ..writeUint8(0x00)
      ..writeUint8(0x00);

    return [writer.toBytes()];
  }
}
