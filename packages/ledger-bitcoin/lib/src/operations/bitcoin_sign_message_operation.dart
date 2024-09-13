import 'dart:typed_data';

import 'package:ledger_bitcoin/src/ledger/ledger_input_operation.dart';
import 'package:ledger_bitcoin/src/utils/bip32_path.dart';
import 'package:ledger_bitcoin/src/utils/int_extension.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class BitcoinSignMessageOperation extends LedgerInputOperation<Uint8List> {
  /// The [derivationPath] is a Bip32-path used to derive the public key/Address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  /// The byte length of the message to sign
  final int messageLength;

  /// The Merkle root of the message, split in 64-byte chunks
  final Uint8List messageMerkleRoot;

  BitcoinSignMessageOperation({
    required this.derivationPath,
    required this.messageLength,
    required this.messageMerkleRoot,
  }) : super(0xE1, 0x10);

  @override
  Future<Uint8List> read(ByteDataReader reader) async =>
      reader.read(reader.remainingLength);

  @override
  int get p1 => 0x00;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> writeInputData() async {
    final path = BIPPath.fromString(derivationPath).toPathArray();

    final writer = ByteDataWriter()
      ..writeUint8(path.length); // Write length of the derivation path

    for (final element in path) {
      writer.writeUint32(element); // Add each part of the path
    }

    writer
      ..write(messageLength.toVarint())
      ..write(messageMerkleRoot);

    return writer.toBytes();
  }
}
