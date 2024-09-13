import 'dart:typed_data';

import 'package:ledger_bitcoin/src/ledger/ledger_input_operation.dart';
import 'package:ledger_bitcoin/src/utils/bip32_path.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

/// Returns an extended public key at the given derivation path, serialized as per BIP-32
class BitcoinExtendedPublicKeyOperation extends LedgerInputOperation<String> {
  /// If [displayPublicKey] is set to true the Public Key will be shown to the user on the ledger device
  final bool displayPublicKey;

  /// The [derivationPath] is a Bip32-path used to derive the public key/Address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  BitcoinExtendedPublicKeyOperation({
    required this.displayPublicKey,
    required this.derivationPath,
  }) : super(0xE1, 0x00);

  @override
  Future<String> read(ByteDataReader reader) async =>
      reader.read(reader.remainingLength).toAsciiString();

  @override
  int get p1 => 0x00;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> writeInputData() async {
    final path = BIPPath.fromString(derivationPath).toPathArray();

    // 0x01 - Show the public key on the device
    // 0x00 - Don't show the public key on the device
    // If the path is not standard, an error is returned
    final displayPublicKeyByte = displayPublicKey ? 0x01 : 0x00;

    final writer = ByteDataWriter()
      ..writeUint8(displayPublicKeyByte)
      ..writeUint8(path.length); // Write length of the derivation path

    for (final element in path) {
      writer.writeUint32(element); // Add each part of the path
    }

    return writer.toBytes();
  }
}
