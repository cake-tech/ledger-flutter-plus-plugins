import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:ledger_nano/src/ledger/ledger_input_operation.dart';
import 'package:ledger_nano/src/ledger/nano_instructions.dart';
import 'package:ledger_nano/src/utils/bip32_path_helper.dart';
import 'package:ledger_nano/src/utils/bip32_path_to_buffer.dart';

/// This command signs a 128bit nonce and returns the signature.
/// "Nano Signed Nonce:\n" + nonceBytes is the message that gets signed with the private key.
/// This method is meant to be used as a soft-authentication (eg for APIs),
/// to prove that the Ledger with the private key is plugged into the computer.
class NanoSignNonceOperation extends LedgerInputOperation<Uint8List> {
  /// The [nonce] is used to sing the message
  final int nonce;

  /// The [derivationPath] is a Bip32-path used to derive the address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  NanoSignNonceOperation(
      {this.nonce = 0, this.derivationPath = "m/44'/165'/0'"})
      : super(nanoCLA, walletAddressINS);

  @override
  Future<Uint8List> read(ByteDataReader reader) async =>
      reader.read(reader.remainingLength);

  @override
  int get p1 => 0x00;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> writeInputData() async {
    final writer = ByteDataWriter();

    final path = BIPPath.fromString(derivationPath).toPathArray();
    writer.write(packDerivationPath(path));

    writer.writeUint16(nonce);
    return writer.toBytes();
  }
}
