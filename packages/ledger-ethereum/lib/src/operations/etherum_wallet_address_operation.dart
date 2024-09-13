import 'dart:typed_data';

import 'package:ledger_ethereum/src/ledger/ethereum_instructions.dart';
import 'package:ledger_ethereum/src/ledger/ledger_input_operation.dart';
import 'package:ledger_ethereum/src/utils/bip32_path_helper.dart';
import 'package:ledger_ethereum/src/utils/bip32_path_to_buffer.dart';
import 'package:ledger_ethereum/src/utils/string_uint8list_extension.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

/// This command returns the public key and Ethereum address for the given BIP 32 path.
class EthereumWalletAddressOperation
    extends LedgerInputOperation<(String, String, String?)> {
  /// If [displayPublicKey] is set to true the Public Key will be shown to the user on the ledger device
  final bool displayPublicKey;

  /// If [displayPublicKey] is set to true the device will also return the chain Code
  // TODO: Clarify what the chaincode is
  final bool returnChainCode;

  /// The [derivationPath] is a Bip32-path used to derive the public key/Address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  EthereumWalletAddressOperation(
      {this.displayPublicKey = false,
      this.returnChainCode = true,
      this.derivationPath = "m/44'/60'/0'/0/0"})
      : super(ethCLA, walletAddressINS);

  @override
  Future<(String, String, String?)> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);
    final publicKeyLength = response[0];
    final addressLength = response[1 + publicKeyLength];

    final publicKey = response.sublist(1, 1 + publicKeyLength);
    final address = response.sublist(
        2 + publicKeyLength, 2 + publicKeyLength + addressLength);

    final chainCode = returnChainCode
        ? response.sublist(2 + publicKeyLength + addressLength)
        : null;

    return (
      publicKey.toHexString(),
      "0x${address.toAsciiString()}",
      chainCode?.toHexString()
    );
  }

  // Send 0x00 to not display the Public Key on the device before returning
  // Send 0x01 to display the Public Key on the device before returning
  @override
  int get p1 => displayPublicKey ? 0x01 : 0x00;

  // Send 0x00 to not return the chain code
  // Send 0x01 to return the chain code
  @override
  int get p2 => returnChainCode ? 0x01 : 0x00;

  @override
  Future<Uint8List> writeInputData() async {
    final path = BIPPath.fromString(derivationPath).toPathArray();
    return packDerivationPath(path);
  }
}
