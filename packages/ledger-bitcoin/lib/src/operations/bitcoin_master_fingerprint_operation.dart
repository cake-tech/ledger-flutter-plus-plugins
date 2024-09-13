import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

/// Returns the fingerprint of the master public key, as defined in BIP-0032#Key identifiers.
/// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#key-identifiers
class BitcoinMasterFingerprintOperation extends LedgerOperation<Uint8List> {
  @override
  Future<Uint8List> read(ByteDataReader reader) async =>
      reader.read(reader.remainingLength);

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer
      ..writeUint8(0xE1)
      ..writeUint8(0x05)
      ..writeUint8(0x00)
      ..writeUint8(0x00)
      ..writeUint8(0x00);

    return [writer.toBytes()];
  }
}
