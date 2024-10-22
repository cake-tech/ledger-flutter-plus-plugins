import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_nano/src/nano_app_config.dart';
import 'package:ledger_nano/src/nano_transformer.dart';
import 'package:ledger_nano/src/operations/nano_app_config_operation.dart';
import 'package:ledger_nano/src/operations/nano_cache_block_operation.dart';
import 'package:ledger_nano/src/operations/nano_sign_block_operation.dart';
import 'package:ledger_nano/src/operations/nano_sign_nonce_operation.dart';
import 'package:ledger_nano/src/operations/nano_wallet_address_operation.dart';

class NanoLedgerApp {
  final NanoTransformer transformer;
  final LedgerConnection connection;

  /// The [derivationPath] is a Bip32-path used to derive the Nano account
  /// If the path is not standard, an error is returned
  String derivationPath;

  NanoLedgerApp(
    this.connection, {
    this.transformer = const NanoTransformer(),
    this.derivationPath = "m/44'/165'/0'",
  });

  Future<List<String>> getAccounts() async {
    final (_, address) = await connection.sendOperation<(String, String)>(
      NanoWalletAddressOperation(derivationPath: derivationPath),
      transformer: transformer,
    );
    return [address];
  }

  Future<NanoAppConfig> getAppConfig() =>
      connection.sendOperation<NanoAppConfig>(
        NanoAppConfigOperation(),
        transformer: transformer,
      );

  /// This command returns the signature for the provided universal block data.
  /// For non-null parent blocks the validate block command needs to be called before the this command.
  Future<(String, String)> signBlock({
    required String parentBlockhash,
    required String link,
    required String representative,
    required int balance,
  }) =>
      connection.sendOperation<(String, String)>(
        NanoSignBlockOperation(
          parentBlockhash: parentBlockhash,
          link: link,
          representative: representative,
          balance: balance,
          derivationPath: derivationPath,
        ),
        transformer: transformer,
      );

  /// This command caches the frontier block in memory. The sign block command
  /// uses this cached data to determine the changes in account state.
  Future<void> cacheBlock({
    required String parentBlockhash,
    required String link,
    required String representative,
    required int balance,
    required String signature,
  }) =>
      connection.sendOperation<Uint8List>(
        NanoCacheBlockOperation(
          parentBlockhash: parentBlockhash,
          link: link,
          representative: representative,
          balance: balance,
          signature: signature,
          derivationPath: derivationPath,
        ),
        transformer: transformer,
      );

  /// This command signs a 128bit nonce and returns the signature.
  /// "Nano Signed Nonce:\n" + nonceBytes is the message that gets signed with the private key.
  /// This method is meant to be used as a soft-authentication (eg for APIs),
  /// to prove that the Ledger with the private key is connected.
  Future<Uint8List> signNonce(int nonce) =>
      connection.sendOperation<Uint8List>(
        NanoSignNonceOperation(nonce: nonce, derivationPath: derivationPath),
        transformer: transformer,
      );
}
