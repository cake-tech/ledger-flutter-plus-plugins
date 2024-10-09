import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:ledger_bitcoin/src/bitcoin_transformer.dart';
import 'package:ledger_bitcoin/src/client_command_interpreter.dart';
import 'package:ledger_bitcoin/src/ledger_app_version.dart';
import 'package:ledger_bitcoin/src/operations/bitcoin_extended_public_key_operation.dart';
import 'package:ledger_bitcoin/src/operations/bitcoin_master_fingerprint_operation.dart';
import 'package:ledger_bitcoin/src/operations/bitcoin_sign_message_operation.dart';
import 'package:ledger_bitcoin/src/operations/bitcoin_sign_psbt_operation.dart';
import 'package:ledger_bitcoin/src/operations/bitcoin_version_operation.dart';
import 'package:ledger_bitcoin/src/operations/bitcoin_wallet_address_operation.dart';
import 'package:ledger_bitcoin/src/operations/framework/continue_interrupted_operation.dart';
import 'package:ledger_bitcoin/src/psbt/constants.dart';
import 'package:ledger_bitcoin/src/psbt/merkelized_psbt.dart';
import 'package:ledger_bitcoin/src/psbt/psbt_extractor.dart';
import 'package:ledger_bitcoin/src/psbt/psbt_finalizer.dart';
import 'package:ledger_bitcoin/src/psbt/psbtv2.dart';
import 'package:ledger_bitcoin/src/utils/bip32_path.dart';
import 'package:ledger_bitcoin/src/utils/create_key_helper.dart';
import 'package:ledger_bitcoin/src/utils/merkle/merkle.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';
import 'package:ledger_bitcoin/src/wallet_policy.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class SpeculosBitcoinLedgerApp {
  BitcoinTransformer transformer;

  final String derivationPath;

  SpeculosBitcoinLedgerApp({
    this.transformer = const BitcoinTransformer(),
    this.derivationPath = "m/84'/0'/0'/0/0",
  });

  Future<List<String>> getAccounts({String? accountsDerivationPath}) async {
    final bipPath =
        BIPPath.fromString(accountsDerivationPath ?? derivationPath);
    final masterFingerprint = await getMasterFingerprint();
    final accountXPub = await getXPubKey(
        derivationPath: bipPath.toHardenedBIPPath().toString());

    final addr = await _getWalletAddress(
      path: bipPath,
      accountXPub: accountXPub,
      masterFingerprint: masterFingerprint,
      descrTempl: "wpkh(@0)",
      display: false,
    );
    return [addr.toAsciiString()];
  }

  Future<LedgerAppVersion> getVersion() =>
      sendOperation<LedgerAppVersion>(BitcoinVersionOperation(),
          transformer: transformer);

  /// Returns an extended public key at the given derivation path, serialized as per BIP-32
  Future<String> getXPubKey({required String derivationPath, bool displayPublicKey = false}) =>
      sendOperation<String>(
          BitcoinExtendedPublicKeyOperation(
              displayPublicKey: displayPublicKey,
              derivationPath: derivationPath),
          transformer: transformer);

  /// Returns the fingerprint of the master public key
  Future<Uint8List> getMasterFingerprint() =>
      sendOperation<Uint8List>(BitcoinMasterFingerprintOperation(),
          transformer: transformer);

  // Base 64 Encoded v, r, s
  Future<Uint8List> signMessage({required Uint8List message}) async {
    final clientInterpreter = ClientCommandInterpreter(() => {});

    // prepare ClientCommandInterpreter
    final nChunks = (message.length / 64).ceil();
    final chunks = <Uint8List>[];
    for (var i = 0; i < nChunks; i++) {
      final end = min(message.length, 64 * i + 64);
      chunks.add(message.sublist(64 * i, end));
    }

    clientInterpreter.addKnownList(chunks);
    final chunksRoot = Merkle(chunks.map((m) => hashLeaf(m)).toList()).root;

    return await runFlow(
      BitcoinSignMessageOperation(
        derivationPath: derivationPath,
        messageLength: message.length,
        messageMerkleRoot: chunksRoot,
      ),
      clientInterpreter,
    );
  }

  Future<Uint8List> _getWalletAddress({
    required BIPPath path,
    required String accountXPub,
    required Uint8List masterFingerprint,
    required String descrTempl,
    required bool display,
  }) async {
    final pathElements = path.toPathArray();
    final accountPath = path.hardenedPath;

    if (accountPath.length + 2 != pathElements.length) return Uint8List(0);

    final policy = WalletPolicy("", descrTempl,
        [createKey(masterFingerprint, accountPath, accountXPub)]);
    final changeAndIndex = pathElements.sublist(pathElements.length - 2);

    return _getWalletAddressWithPolicy(
        policy: policy,
        change: changeAndIndex.first,
        addressIndex: changeAndIndex.last,
        display: display);
  }

  Future<Uint8List> _getWalletAddressWithPolicy({
    required WalletPolicy policy,
    required int change,
    required int addressIndex,
    required bool display,
  }) async {
    final clientInterpreter = ClientCommandInterpreter(() {});
    clientInterpreter
        .addKnownList(policy.keys.map((k) => ascii.encode(k)).toList());
    clientInterpreter.addKnownPreimage(policy.serialize());

    return await runFlow(
      BitcoinWalletAddressOperation(
        walletPolicy: policy,
        change: change,
        addressIndex: addressIndex,
        displayWalletAddress: display,
      ),
      clientInterpreter,
    );
  }

  Future<Uint8List> signPsbt({
    required PsbtV2 psbt,
  }) async {
    final bipPath = BIPPath.fromString(derivationPath);
    final masterFingerprint = await getMasterFingerprint();
    final accountXPub = await getXPubKey(
        derivationPath: bipPath.toHardenedBIPPath().toString());

    return _signPsbt(
        psbt: psbt,
        walletPolicy: NativeSegwitWalletPolicy(
            [createKey(masterFingerprint, bipPath.hardenedPath, accountXPub)]));
  }

  Future<Uint8List> _signPsbt({
    required PsbtV2 psbt,
    required WalletPolicy walletPolicy,
    Uint8List? walletHMAC,
  }) async {
    final merkelizedPsbt = MerkelizedPsbt(psbt);

    if (walletHMAC != null && walletHMAC.length != 32) {
      throw Exception("Invalid HMAC length");
    }

    // prepare ClientCommandInterpreter
    final clientInterpreter = ClientCommandInterpreter(() {})
      ..addKnownList(walletPolicy.keys.map((k) => ascii.encode(k)).toList())
      ..addKnownPreimage(walletPolicy.serialize())
      ..addKnownMapping(merkelizedPsbt.globalMerkleMap);

    for (final map in merkelizedPsbt.inputMerkleMaps) {
      clientInterpreter.addKnownMapping(map);
    }
    for (final map in merkelizedPsbt.outputMerkleMaps) {
      clientInterpreter.addKnownMapping(map);
    }

    clientInterpreter.addKnownList(merkelizedPsbt.inputMapCommitments);
    final inputMapsRoot = Merkle(
      merkelizedPsbt.inputMapCommitments.map((m) => hashLeaf(m)),
    ).root;
    clientInterpreter.addKnownList(merkelizedPsbt.outputMapCommitments);
    final outputMapsRoot = Merkle(
      merkelizedPsbt.outputMapCommitments.map((m) => hashLeaf(m)),
    ).root;

    await runFlow(
      BitcoinSignPsbtOperation(
          walletPolicy: walletPolicy,
          globalKeysValuesRoot: merkelizedPsbt.globalKeysValuesRoot,
          inputCount: merkelizedPsbt.getGlobalInputCount(),
          inputsMapsRoot: inputMapsRoot,
          outputCount: merkelizedPsbt.getGlobalOutputCount(),
          outputsMapsRoot: outputMapsRoot),
      clientInterpreter,
    );

    final yielded = clientInterpreter.yielded;

    final sigs = <int, Uint8List>{};
    for (final inputAndSig in yielded) {
      sigs[inputAndSig[0]] = inputAndSig.sublist(1);
    }

    sigs.forEach((k, v) {
      // Note: Looking at BIP32 derivation does not work in the generic case,
      // since some inputs might not have a BIP32-derived pubkey.
      final pubkeys = psbt.getInputKeyDatas(k, PSBTIn.bip32Derivation);
      if (pubkeys.length != 1) {
        // No legacy BIP32_DERIVATION, assume we're using taproot.
        final pubkey = psbt.getInputKeyDatas(k, PSBTIn.tapBip32Derivation);
        if (pubkey.isEmpty) {
          throw Exception('Missing pubkey derivation for input $k');
        }
        psbt.setInputTapKeySig(k, v);
      } else {
        final pubkey = pubkeys[0];
        psbt.setInputPartialSig(k, pubkey, v);
      }
    });

    psbt.finalize();
    return psbt.extract();
  }
}

Future<T> sendOperation<T>(LedgerRawOperation<T> operation,
    {LedgerTransformer? transformer}) async {
  final writer = ByteDataWriter();
  await operation.write(writer);

  final response = await sendReq(hex.encode(writer.toBytes()));
  final data = hex.decode(response["data"]! as String) as Uint8List;
  final reader = ByteDataReader();
  if (transformer != null) {
    final transformed = await transformer.onTransform([data]);
    reader.add(transformed);
  } else {
    reader.add(data);
  }

  return operation.read(reader);

}

Future<Map<String, dynamic>> sendReq(String payload) async {
  var res = await http.post(Uri.parse("http://localhost:5000/apdu"),
      headers: {"Content-Type": "application/json"},
      body: '{"data": "$payload"}');

  return jsonDecode(res.body);
}

Future<Uint8List> runFlow(LedgerRawOperation<Uint8List> operation,
    ClientCommandInterpreter cci) async {
  var response = await sendOperation<Uint8List>(operation);

  while (response.sublist(response.length - 2).toHexString() == "e000") {
    final hwRequest =
    response.sublist(0, response.length - 2); // -2 because we need to remove the status bytes
    final commandResponse = cci.execute(hwRequest);

    response = await _continueOperation(data: commandResponse);
  }

  if (response.toHexString() == "6a80") throw Exception("SW_INCORRECT_DATA");
  if (response.toHexString() == "6a82") throw Exception("SW_NOT_SUPPORTED");

  print("Final response: ${response.toHexString()}");

  return response.sublist(
      0, response.length - 2); // -2 because we need to remove the status bytes
}

Future<Uint8List> _continueOperation({required Uint8List data}) =>
    sendOperation<Uint8List>(ContinueInterruptedOperation(data));
