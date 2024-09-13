import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/address_format.dart';
import 'package:ledger_litecoin/src/ledger/ledger_input_operation.dart';
import 'package:ledger_litecoin/src/ledger/litecoin_instructions.dart';
import 'package:ledger_litecoin/src/utils/bip32_path_helper.dart';
import 'package:ledger_litecoin/src/utils/bip32_path_to_buffer.dart';
import 'package:ledger_litecoin/src/utils/string_uint8list_extension.dart';

/// This command returns the public key and Base58 encoded address for the given BIP 32 path.
/// The Base58 encoded address can be displayed on the device screen.
/// This call might trigger a user validation (with or without token) if the
/// device has the public key protection setting enabled. The last token
/// approved by the user is saved, re-using it in following calls makes it possible
/// to avoid requesting more validation in a row to the user.
class LitecoinWalletAddressOperation
    extends LedgerInputOperation<(String, String, Uint8List)> {
  /// If [displayAddress] is set to true the address will be shown to the user on the ledger device
  final bool displayAddress;

  final AddressFormat addressFormat;

  /// The [derivationPath] is a Bip32-path used to derive the public key/Address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  LitecoinWalletAddressOperation({
    this.displayAddress = false,
    this.addressFormat = AddressFormat.bech32,
    this.derivationPath = "m/84'/2'/0'/0/0",
  }) : super(btcCLA, walletAddressINS);

  @override
  Future<(String, String, Uint8List)> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);
    final publicKeyLength = response[0];
    final addressLength = response[1 + publicKeyLength];

    final publicKey = response.sublist(1, 1 + publicKeyLength);
    final address = response.sublist(
        2 + publicKeyLength, 2 + publicKeyLength + addressLength);

    final chainCode = response.sublist(2 + publicKeyLength + addressLength);

    return (publicKey.toHexString(), (address.toAsciiString()), chainCode);
  }

  // Send 0x00 to not display the Public Key on the device before returning
  // Send 0x01 to display the Public Key on the device before returning
  @override
  int get p1 => displayAddress ? 0x01 : 0x00;

  @override
  int get p2 => addressFormat.byteData;

  @override
  Future<Uint8List> writeInputData() async {
    final path = BIPPath.fromString(derivationPath).toPathArray();
    return packDerivationPath(path);
  }
}
