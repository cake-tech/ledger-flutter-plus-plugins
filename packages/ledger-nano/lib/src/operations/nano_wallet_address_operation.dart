import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:ledger_nano/src/ledger/ledger_input_operation.dart';
import 'package:ledger_nano/src/ledger/nano_instructions.dart';
import 'package:ledger_nano/src/utils/bip32_path_helper.dart';
import 'package:ledger_nano/src/utils/bip32_path_to_buffer.dart';
import 'package:ledger_nano/src/utils/string_uint8list_extension.dart';

/// This command returns the public key and Nano address for the given BIP 32 path.
class NanoWalletAddressOperation
    extends LedgerInputOperation<(String, String)> {
  /// If [displayAddress] is set to true the Nano address will be shown to the user on the ledger device
  final bool displayAddress;

  /// The [derivationPath] is a Bip32-path used to derive the address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  NanoWalletAddressOperation(
      {this.displayAddress = false, this.derivationPath = "m/44'/165'/0'"})
      : super(nanoCLA, walletAddressINS);

  @override
  Future<(String, String)> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);
    final publicKey = response.sublist(0, 32);
    final accountAddressLength = response[32];
    final address =
        response.sublist(33, 33 + accountAddressLength);

    return (publicKey.toHexString(), address.toAsciiString());
  }

  // Send 0x00 to not display the Wallet Address on the device before returning
  // Send 0x01 to display the Wallet Address on the device before returning
  @override
  int get p1 => displayAddress ? 0x01 : 0x00;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> writeInputData() async {
    final path = BIPPath.fromString(derivationPath).toPathArray();

    return packDerivationPath(path);
  }
}
