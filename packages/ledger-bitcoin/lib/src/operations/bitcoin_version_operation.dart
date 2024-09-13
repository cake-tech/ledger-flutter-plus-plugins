import 'dart:convert';
import 'dart:typed_data';

import 'package:ledger_bitcoin/src/ledger_app_version.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class BitcoinVersionOperation extends LedgerOperation<LedgerAppVersion> {
  final bool display = false;

  @override
  Future<LedgerAppVersion> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);

    var i = 0;
    final format = response[i++];
    if (format != 1) throw Exception("Unexpected response");

    final nameLength = response[i++];
    final name = ascii.decode(response.sublist(i, (i += nameLength)));
    final versionLength = response[i++];
    final version = ascii.decode(response.sublist(i, (i += versionLength)));
    final flagLength = response[i++];
    final flags = response.sublist(i, (i += flagLength));

    return LedgerAppVersion(name, version, flags);
  }

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer
      ..writeUint8(0xB0)
      ..writeUint8(0x01)
      ..writeUint8(0x00)
      ..writeUint8(0x00);

    return [writer.toBytes()];
  }
}
