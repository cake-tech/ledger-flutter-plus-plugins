import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ledger_bitcoin/src/psbt/constants.dart';
import 'package:ledger_bitcoin/src/psbt/psbtv2.dart';
import 'package:ledger_bitcoin/src/utils/buffer_writer.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';
import 'package:ledger_bitcoin/src/utils/utils.dart';

class SpendingCondition {
  final Uint8List scriptPubKey;
  final Uint8List? redeemScript;

  SpendingCondition({required this.scriptPubKey, this.redeemScript});
// Possible future extension:
// final Uint8List? witnessScript; // For p2wsh witnessScript
// tapScript?: {tapPath: List<Uint8List>, script: Uint8List} // For taproot
}

class SpentOutput {
  final SpendingCondition cond;
  final Uint8List amount;

  SpentOutput(this.cond, this.amount);
}

/// Encapsulates differences between account types, for example p2wpkh,
/// p2wpkhWrapped, p2tr.
abstract class AccountType {
  /// Generates a scriptPubKey (output script) from a list of public keys. If a
  /// p2sh redeemScript or a p2wsh witnessScript is needed it will also be set on
  /// the returned SpendingCondition.
  ///
  /// The pubkeys are expected to be 33 byte ecdsa compressed pubkeys.
  SpendingCondition spendingCondition(List<Uint8List> pubkeys);

  /// Populates the psbt with account type-specific data for an input.
  /// [i] The index of the input map to populate
  /// [inputTx] The full transaction containing the spent output. This may
  /// be omitted for taproot.
  /// [spentOutput] The amount and spending condition of the spent output
  /// [pubkeys] The 33 byte ecdsa compressed public keys involved in the input
  /// [pathElems] The paths corresponding to the pubkeys, in same order.
  void setInput(int i, Uint8List? inputTx, SpentOutput spentOutput,
      List<Uint8List> pubkeys, List<List<int>> pathElems);

  /// Populates the psbt with account type-specific data for an output. This is typically
  /// done for change outputs and other outputs that goes to the same account as
  /// being spent from.
  /// [i] The index of the output map to populate
  /// [cond] The spending condition for this output
  /// [pubkeys] The 33 byte ecdsa compressed public keys involved in this output
  /// [paths] The paths corresponding to the pubkeys, in same order.
  void setOwnOutput(int i, SpendingCondition cond, List<Uint8List> pubkeys,
      List<List<int>> paths);

  /// Returns the descriptor template for this account type. Currently only
  /// DefaultDescriptorTemplates are allowed, but that might be changed in the
  /// future. See class WalletPolicy for more information on descriptor
  /// templates.
  String getDescriptorTemplate();
}

abstract class BaseAccount implements AccountType {
  final PsbtV2 psbt;
  final Uint8List masterFp;

  BaseAccount(this.psbt, this.masterFp);
}

/// Superclass for single signature accounts. This will make sure that the pubkey
/// arrays and path arrays in the method arguments contains exactly one element
/// and calls an abstract method to do the actual work.
abstract class SingleKeyAccount extends BaseAccount {
  SingleKeyAccount(super.psbt, super.masterFp);

  @override
  SpendingCondition spendingCondition(List<Uint8List> pubkeys) {
    if (pubkeys.length != 1) {
      throw Exception("Expected single key, got ${pubkeys.length}");
    }
    return singleKeyCondition(pubkeys[0]);
  }

  SpendingCondition singleKeyCondition(Uint8List pubkey);

  @override
  void setInput(int i, Uint8List? inputTx, SpentOutput spentOutput,
      List<Uint8List> pubkeys, List<List<int>> pathElems) {
    if (pubkeys.length != 1) {
      throw Exception("Expected single key, got ${pubkeys.length}");
    }
    if (pathElems.length != 1) {
      throw Exception("Expected single path, got ${pathElems.length}");
    }
    setSingleKeyInput(i, inputTx, spentOutput, pubkeys[0], pathElems[0]);
  }

  void setSingleKeyInput(int i, Uint8List? inputTx, SpentOutput spentOutput,
      Uint8List pubkey, List<int> path);

  @override
  void setOwnOutput(int i, SpendingCondition cond, List<Uint8List> pubkeys,
      List<List<int>> paths) {
    if (pubkeys.length != 1) {
      throw Exception("Expected single key, got ${pubkeys.length}");
    }
    if (paths.length != 1) {
      throw Exception("Expected single path, got ${paths.length}");
    }
    setSingleKeyOutput(i, cond, pubkeys[0], paths[0]);
  }

  void setSingleKeyOutput(
      int i, SpendingCondition cond, Uint8List pubkey, List<int> path);
}

class p2pkh extends SingleKeyAccount {
  p2pkh(super.psbt, super.masterFp);

  @override
  SpendingCondition singleKeyCondition(Uint8List pubkey) {
    final buf = BufferWriter();
    final pubkeyHash = hashPublicKey(pubkey);
    buf.writeSlice(Uint8List.fromList([OP_DUP, OP_HASH160, HASH_SIZE]));
    buf.writeSlice(pubkeyHash);
    buf.writeSlice(Uint8List.fromList([OP_EQUALVERIFY, OP_CHECKSIG]));
    return SpendingCondition(scriptPubKey: buf.buffer());
  }

  @override
  void setSingleKeyInput(int i, Uint8List? inputTx, SpentOutput spentOutput,
      Uint8List pubkey, List<int> path) {
    if (inputTx == null) {
      throw Exception("Full input base transaction required");
    }
    psbt.setInputNonWitnessUtxo(i, inputTx);
    psbt.setInputBip32Derivation(i, pubkey, masterFp, path);
  }

  @override
  void setSingleKeyOutput(
          int i, SpendingCondition cond, Uint8List pubkey, List<int> path) =>
      psbt.setOutputBip32Derivation(i, pubkey, masterFp, path);

  @override
  String getDescriptorTemplate() => "pkh(@0)";
}

class p2tr extends SingleKeyAccount {
  p2tr(super.psbt, super.masterFp);

  @override
  SpendingCondition singleKeyCondition(Uint8List pubkey) {
    final xonlyPubkey = pubkey.sublist(1); // x-only pubkey
    final buf = BufferWriter();
    final outputKey = getTaprootOutputKey(xonlyPubkey);
    buf.writeSlice(Uint8List.fromList([0x51, 32])); // push1, pubkeylen
    buf.writeSlice(outputKey);
    return SpendingCondition(scriptPubKey: buf.buffer());
  }

  @override
  void setSingleKeyInput(int i, Uint8List? inputTx, SpentOutput spentOutput,
      Uint8List pubkey, List<int> path) {
    final xonly = pubkey.sublist(1);
    psbt.setInputTapBip32Derivation(i, xonly, [], masterFp, path);
    psbt.setInputWitnessUtxo(
        i, spentOutput.amount, spentOutput.cond.scriptPubKey);
  }

  @override
  void setSingleKeyOutput(
      int i, SpendingCondition cond, Uint8List pubkey, List<int> path) {
    final xonly = pubkey.sublist(1);
    psbt.setOutputTapBip32Derivation(i, xonly, [], masterFp, path);
  }

  @override
  String getDescriptorTemplate() => "tr(@0)";

  // The following two functions are copied from wallet-btc and adapted.
  // They should be moved to a library to avoid code reuse.
  Uint8List _hashTapTweak(Uint8List x) {
    // hash_tag(x) = SHA256(SHA256(tag) || SHA256(tag) || x), see BIP340
    // See https://github.com/bitcoin/bips/blob/master/bip-0340.mediawiki#specification
    final h = sha256Hasher(utf8.encode("TapTweak"));
    return sha256Hasher(Uint8List.fromList([...h, ...h, ...x]));
  }

  /// Calculates a taproot output key from an internal key. This output key will be
  /// used as witness program in a taproot output. The internal key is tweaked
  /// according to recommendation in BIP341:
  /// https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#cite_ref-22-0
  ///
  /// @param internalPubkey A 32 byte x-only taproot internal key
  /// @returns The output key
  Uint8List getTaprootOutputKey(Uint8List internalPubkey) {
    if (internalPubkey.length != 32) {
      throw Exception("Expected 32 byte pubkey. Got ${internalPubkey.length}");
    }
    // A BIP32 derived key can be converted to a schnorr pubkey by dropping
    // the first byte, which represent the oddness/evenness. In schnorr all
    // pubkeys are even.
    // https://github.com/bitcoin/bips/blob/master/bip-0340.mediawiki#public-key-conversion
    final evenEcdsaPubkey = Uint8List.fromList([0x02, ...internalPubkey]);
    final tweak = _hashTapTweak(internalPubkey);

    // Q = P + int(hash_TapTweak(bytes(P)))G
    final outputEcdsaKey = pointAddScalar(evenEcdsaPubkey, tweak);
    // Convert to schnorr.
    final outputSchnorrKey = outputEcdsaKey.sublist(1);
    // Create address
    return outputSchnorrKey;
  }
}

class p2wpkhWrapped extends SingleKeyAccount {
  p2wpkhWrapped(super.psbt, super.masterFp);

  @override
  SpendingCondition singleKeyCondition(Uint8List pubkey) {
    final buf = BufferWriter();
    final redeemScript = _createRedeemScript(pubkey);
    final scriptHash = hashPublicKey(redeemScript);
    buf.writeSlice(Uint8List.fromList([OP_HASH160, HASH_SIZE]));
    buf.writeSlice(scriptHash);
    buf.writeUInt8(OP_EQUAL);
    return SpendingCondition(
        scriptPubKey: buf.buffer(), redeemScript: redeemScript);
  }

  @override
  void setSingleKeyInput(int i, Uint8List? inputTx, SpentOutput spentOutput,
      Uint8List pubkey, List<int> path) {
    if (inputTx == null) {
      throw Exception("Full input base transaction required");
    }
    psbt.setInputNonWitnessUtxo(i, inputTx);
    psbt.setInputBip32Derivation(i, pubkey, masterFp, path);

    final userSuppliedRedeemScript = spentOutput.cond.redeemScript;
    final expectedRedeemScript = _createRedeemScript(pubkey);
    if (userSuppliedRedeemScript != null &&
        expectedRedeemScript == userSuppliedRedeemScript) {
// At what point might a user set the redeemScript on its own?
      throw Exception(
          "User-supplied redeemScript ${userSuppliedRedeemScript.toHexString()} doesn't match expected ${expectedRedeemScript.toHexString()} for input $i");
    }
    psbt.setInputRedeemScript(i, expectedRedeemScript);
    psbt.setInputWitnessUtxo(
        i, spentOutput.amount, spentOutput.cond.scriptPubKey);
  }

  @override
  void setSingleKeyOutput(
      int i, SpendingCondition cond, Uint8List pubkey, List<int> path) {
    psbt.setOutputRedeemScript(i, cond.redeemScript!);
    psbt.setOutputBip32Derivation(i, pubkey, masterFp, path);
  }

  @override
  String getDescriptorTemplate() => "sh(wpkh(@0))";

  Uint8List _createRedeemScript(Uint8List pubkey) {
    final pubkeyHash = hashPublicKey(pubkey);
    return Uint8List.fromList([...hex.decode("0014"), ...pubkeyHash]);
  }
}

class p2wpkh extends SingleKeyAccount {
  p2wpkh(super.psbt, super.masterFp);

  @override
  SpendingCondition singleKeyCondition(Uint8List pubkey) {
    final buf = BufferWriter();
    final pubkeyHash = hashPublicKey(pubkey);
    buf.writeSlice(Uint8List.fromList([0, HASH_SIZE]));
    buf.writeSlice(pubkeyHash);
    return SpendingCondition(scriptPubKey: buf.buffer());
  }

  @override
  void setSingleKeyInput(int i, Uint8List? inputTx, SpentOutput spentOutput,
      Uint8List pubkey, List<int> path) {
    if (inputTx == null) {
      throw Exception("Full input base transaction required");
    }
    psbt.setInputNonWitnessUtxo(i, inputTx);
    psbt.setInputBip32Derivation(i, pubkey, masterFp, path);
    psbt.setInputWitnessUtxo(
        i, spentOutput.amount, spentOutput.cond.scriptPubKey);
  }

  @override
  void setSingleKeyOutput(
          int i, SpendingCondition cond, Uint8List pubkey, List<int> path) =>
      psbt.setOutputBip32Derivation(i, pubkey, masterFp, path);

  @override
  String getDescriptorTemplate() => "wpkh(@0)";
}
