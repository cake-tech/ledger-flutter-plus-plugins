import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/address_format.dart';
import 'package:ledger_litecoin/src/coin_version.dart';
import 'package:ledger_litecoin/src/firmware_version.dart';
import 'package:ledger_litecoin/src/litecoin_transformer.dart';
import 'package:ledger_litecoin/src/operations/litecoin_app_config_operation.dart';
import 'package:ledger_litecoin/src/operations/litecoin_coin_version_operation.dart';
import 'package:ledger_litecoin/src/operations/litecoin_sign_msg_operation.dart';
import 'package:ledger_litecoin/src/operations/litecoin_wallet_address_operation.dart';
import 'package:ledger_litecoin/src/tx_utils/create_transaction.dart' as tx;
import 'package:ledger_litecoin/src/tx_utils/transaction.dart';
import 'package:ledger_litecoin/src/utils/bip32_path_helper.dart';
import 'package:ledger_litecoin/src/utils/make_xpub.dart';
import 'package:ledger_litecoin/src/utils/string_uint8list_extension.dart'
    as uint_8_list_h;

class LitecoinLedgerApp {
  final LitecoinTransformer transformer;
  final LedgerConnection connection;

  /// The [derivationPath] is a Bip32-path used to derive the public key/Address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  LitecoinLedgerApp(
    this.connection, {
    this.transformer = const LitecoinTransformer(),
    this.derivationPath = "m/84'/2'/0'/0/0",
  });

  Future<List<String>> getAccounts({
    String? accountsDerivationPath,
    AddressFormat addressFormat = AddressFormat.bech32,
  }) async {
    final (_, address, _) =
        await connection.sendOperation<(String, String, Uint8List?)>(
      LitecoinWalletAddressOperation(
          addressFormat: addressFormat,
          derivationPath: accountsDerivationPath ?? derivationPath),
      transformer: transformer,
    );
    return [address];
  }

  /// Returns an extended public key at the given derivation path, serialized as per BIP-32
  Future<String> getXPubKey({
    String? accountsDerivationPath,
    int xPubVersion = 0x0488b21e,
    AddressFormat addressFormat = AddressFormat.bech32,
  }) async {
    final (pubKey, _, chainCode) =
        await connection.sendOperation<(String, String, Uint8List)>(
      LitecoinWalletAddressOperation(
          addressFormat: addressFormat,
          derivationPath: accountsDerivationPath ?? derivationPath),
      transformer: transformer,
    );

    final dPath = BIPPath.fromString(accountsDerivationPath ?? derivationPath);
    final xpub = makeXpub(xPubVersion, dPath.toPathArray(), chainCode,
        uint_8_list_h.fromHexString(pubKey));
    return xpub;
  }

  Future<FirmwareVersion> getVersion() => getAppConfig();

  Future<FirmwareVersion> getAppConfig() =>
      connection.sendOperation<FirmwareVersion>(
        LitecoinAppConfigOperation(),
        transformer: transformer,
      );

  Future<CoinVersion> getCoinVersion() => connection.sendOperation<CoinVersion>(
        LitecoinCoinVersionOperation(),
        transformer: transformer,
      );

  /// This command is used to sign message using a private key.
  ///
  /// The signature is performed as follows:
  /// The [message] to sign is the magic "\x19Litecoin Signed Message:\n" -
  /// followed by the length of the message to sign on 1 byte (if requested) followed by the binary content of the message
  /// The signature is performed on a double SHA-256 hash of the data to sign using the selected private key
  ///
  ///
  /// The signature is returned using the standard ASN-1 encoding.
  /// To convert it to the proprietary Bitcoin-QT format, the host has to :
  ///
  /// Get the parity of the first byte (sequence) : P
  /// Add 27 to P if the public key is not compressed, otherwise add 31 to P
  /// Return the Base64 encoded version of P || r || s
  Future<Uint8List> signMessage(Uint8List message) =>
      connection.sendOperation<Uint8List>(
        LitecoinSignMsgOperation(message, derivationPath),
        transformer: transformer,
      );

  Future<String> createTransaction({
    required List<LedgerTransaction> inputs,
    required List<TransactionOutput> outputs,
    required int sigHashType,
    bool isSegWit = false,
    bool useTrustedInputForSegwit = true,
    List<String> additionals = const [],
    String? changePath,
    int? lockTime,
    void Function(int progress, int total, int index)? onDeviceStreaming,
    void Function()? onDeviceSignatureRequested,
  }) =>
      tx.createTransaction(
        connection,
        transformer,
        inputs: inputs,
        outputs: outputs,
        sigHashType: sigHashType,
        isSegWit: isSegWit,
        useTrustedInputForSegwit: useTrustedInputForSegwit,
        additionals: additionals,
        changePath: changePath,
        lockTime: lockTime,
      );
}
