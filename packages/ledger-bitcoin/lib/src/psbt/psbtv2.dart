import 'dart:core';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ledger_bitcoin/src/psbt/constants.dart';
import 'package:ledger_bitcoin/src/psbt/keypair.dart';
import 'package:ledger_bitcoin/src/utils/buffer_reader.dart';
import 'package:ledger_bitcoin/src/utils/buffer_writer.dart';
import 'package:ledger_bitcoin/src/utils/int_extension.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';

/// Implements Partially Signed Bitcoin Transaction version 2, BIP370, as
/// documented at https://github.com/bitcoin/bips/blob/master/bip-0370.mediawiki
/// and https://github.com/bitcoin/bips/blob/master/bip-0174.mediawiki
///
/// A psbt is a data structure that can carry all relevant information about a
/// transaction through all stages of the signing process. From constructing an
/// unsigned transaction to extracting the final serialized transaction ready for
/// broadcast.
///
/// This implementation is limited to what's needed in ledger_bitcoin to carry
/// out its duties, which means that support for features like multisig or
/// taproot script path spending are not implemented. Specifically, it supports
/// p2pkh, p2wpkhWrappedInP2sh, p2wpkh and p2tr key path spending.
///
/// This class is made purposefully dumb, so it's easy to add support for
/// complementary fields as needed in the future.
class PsbtV2 {
  final globalMap = <String, Uint8List>{};
  final inputMaps = <Map<String, Uint8List>>[];
  final outputMaps = <Map<String, Uint8List>>[];

  void setGlobalTxVersion(int version) =>
      _setGlobal(PSBTGlobal.txVersion, version.toUint32LE());

  int getGlobalTxVersion() => _getGlobal(PSBTGlobal.txVersion).readUint32LE(0);

  void setGlobalFallbackLocktime(int locktime) =>
      _setGlobal(PSBTGlobal.fallbackLocktime, locktime.toUint32LE());

  int? getGlobalFallbackLocktime() =>
      _getGlobalOptional(PSBTGlobal.fallbackLocktime)?.readUint32LE(0);

  void setGlobalInputCount(int inputCount) =>
      _setGlobal(PSBTGlobal.inputCount, inputCount.toVarint());

  int getGlobalInputCount() => intFromVarint(_getGlobal(PSBTGlobal.inputCount));

  void setGlobalOutputCount(int outputCount) =>
      _setGlobal(PSBTGlobal.outputCount, outputCount.toVarint());

  int getGlobalOutputCount() =>
      intFromVarint(_getGlobal(PSBTGlobal.outputCount));

  void setGlobalTxModifiable(Uint8List byte) =>
      _setGlobal(PSBTGlobal.txModifiable, byte);

  Uint8List? getGlobalTxModifiable() =>
      _getGlobalOptional(PSBTGlobal.txModifiable);

  void setGlobalPsbtVersion(int psbtVersion) =>
      _setGlobal(PSBTGlobal.version, psbtVersion.toUint32LE());

  int getGlobalPsbtVersion() => _getGlobal(PSBTGlobal.version).readUint32LE(0);

  void setInputNonWitnessUtxo(int inputIndex, Uint8List transaction) =>
      _setInput(inputIndex, PSBTIn.nonWitnessUTXO, _b(), transaction);

  Uint8List? getInputNonWitnessUtxo(int inputIndex) =>
      _getInputOptional(inputIndex, PSBTIn.nonWitnessUTXO, _b());

  void setInputWitnessUtxo(int inputIndex, Uint8List amount, Uint8List scriptPubKey) {
    final buf = BufferWriter()
      ..writeSlice(amount)
      ..writeVarSlice(scriptPubKey);
    _setInput(inputIndex, PSBTIn.witnessUTXO, _b(), buf.buffer());
  }

  (Uint8List, Uint8List)? getInputWitnessUtxo(int inputIndex) {
    final utxo = _getInputOptional(inputIndex, PSBTIn.witnessUTXO, _b());
    if (utxo == null) return null;
    final buf = BufferReader(utxo);
    return (buf.readSlice(8), buf.readVarSlice());
  }

  void setInputPartialSig(
          int inputIndex, Uint8List pubkey, Uint8List signature) =>
      _setInput(inputIndex, PSBTIn.partialSig, pubkey, signature);

  Uint8List? getInputPartialSig(int inputIndex, Uint8List pubkey) =>
      _getInputOptional(inputIndex, PSBTIn.partialSig, pubkey);

  void setInputSighashType(int inputIndex, int sigHashtype) =>
      _setInput(inputIndex, PSBTIn.sighashType, _b(), sigHashtype.toUint32LE());

  int? getInputSighashType(int inputIndex) =>
      _getInputOptional(inputIndex, PSBTIn.sighashType, _b())?.readUint32LE(0);

  void setInputRedeemScript(int inputIndex, Uint8List redeemScript) =>
      _setInput(inputIndex, PSBTIn.redeemScript, _b(), redeemScript);

  Uint8List? getInputRedeemScript(int inputIndex) =>
      _getInputOptional(inputIndex, PSBTIn.redeemScript, _b());

  void setInputBip32Derivation(int inputIndex, Uint8List pubkey,
      Uint8List masterFingerprint, List<int> path) {
    if (pubkey.length != 33) {
      throw Exception("Invalid pubkey length: ${pubkey.length}");
    }
    _setInput(
      inputIndex,
      PSBTIn.bip32Derivation,
      pubkey,
      _encodeBip32Derivation(masterFingerprint, path),
    );
  }

  (Uint8List, List<int>)? getInputBip32Derivation(
      int inputIndex, Uint8List pubkey) {
    final buf = _getInputOptional(inputIndex, PSBTIn.bip32Derivation, pubkey);
    if (buf == null) return null;
    return _decodeBip32Derivation(buf);
  }

  void setInputFinalScriptsig(int inputIndex, Uint8List scriptSig) =>
      _setInput(inputIndex, PSBTIn.finalScriptsig, _b(), scriptSig);

  Uint8List? getInputFinalScriptsig(int inputIndex) =>
      _getInputOptional(inputIndex, PSBTIn.finalScriptsig, _b());

  void setInputFinalScriptwitness(int inputIndex, Uint8List scriptWitness) =>
      _setInput(inputIndex, PSBTIn.finalScriptwitness, _b(), scriptWitness);

  Uint8List getInputFinalScriptwitness(int inputIndex) =>
      _getInput(inputIndex, PSBTIn.finalScriptwitness, _b());

  void setInputPreviousTxId(int inputIndex, Uint8List txid) =>
      _setInput(inputIndex, PSBTIn.previousTXID, _b(), txid);

  Uint8List getInputPreviousTxid(int inputIndex) =>
      _getInput(inputIndex, PSBTIn.previousTXID, _b());

  void setInputOutputIndex(int inputIndex, int outputIndex) =>
      _setInput(inputIndex, PSBTIn.outputIndex, _b(), outputIndex.toUint32LE());

  int getInputOutputIndex(int inputIndex) =>
      _getInput(inputIndex, PSBTIn.outputIndex, _b()).readUint32LE(0);

  void setInputSequence(int inputIndex, int sequence) =>
      _setInput(inputIndex, PSBTIn.sequence, _b(), sequence.toUint32LE());

  int getInputSequence(int inputIndex) =>
      _getInputOptional(inputIndex, PSBTIn.sequence, _b())?.readUint32LE(0) ??
      0xffffffff;

  void setInputTapKeySig(int inputIndex, Uint8List sig) =>
      _setInput(inputIndex, PSBTIn.tapKeySig, _b(), sig);

  Uint8List? getInputTapKeySig(int inputIndex) =>
      _getInputOptional(inputIndex, PSBTIn.tapKeySig, _b());

  void setInputTapBip32Derivation(int inputIndex, Uint8List pubkey,
      List<Uint8List> hashes, Uint8List masterFingerprint, List<int> path) {
    if (pubkey.length != 32) {
      throw Exception("Invalid pubkey length: ${pubkey.length}");
    }
    final buf = _encodeTapBip32Derivation(hashes, masterFingerprint, path);
    _setInput(inputIndex, PSBTIn.tapBip32Derivation, pubkey, buf);
  }

  (List<Uint8List>, Uint8List, List<int>) getInputTapBip32Derivation(
          int inputIndex, Uint8List pubkey) =>
      _decodeTapBip32Derivation(
          _getInput(inputIndex, PSBTIn.tapBip32Derivation, pubkey));

  List<Uint8List> getInputKeyDatas(int inputIndex, PSBTIn keyType) =>
      _getKeyDatas(inputMaps[inputIndex], keyType.value);

  void setOutputRedeemScript(int outputIndex, Uint8List redeemScript) =>
      _setOutput(outputIndex, PSBTOut.redeemScript, _b(), redeemScript);

  Uint8List getOutputRedeemScript(int outputIndex) =>
      _getOutput(outputIndex, PSBTOut.redeemScript, _b());

  void setOutputBip32Derivation(
          int outputIndex, Uint8List pubkey, Uint8List masterFingerprint, List<int> path) =>
      _setOutput(
        outputIndex,
        PSBTOut.bip32Derivation,
        pubkey,
        _encodeBip32Derivation(masterFingerprint, path),
      );

  (Uint8List, List<int>) getOutputBip32Derivation(
          int outputIndex, Uint8List pubkey) =>
      _decodeBip32Derivation(
          _getOutput(outputIndex, PSBTOut.bip32Derivation, pubkey));

  void setOutputAmount(int outputIndex, int amount) =>
      _setOutput(outputIndex, PSBTOut.amount, _b(), amount.toUint64LE());

  int getOutputAmount(int outputIndex) =>
      _getOutput(outputIndex, PSBTOut.amount, _b()).readUint64LE(0);

  void setOutputScript(int outputIndex, Uint8List scriptPubKey) =>
      _setOutput(outputIndex, PSBTOut.script, _b(), scriptPubKey);

  Uint8List getOutputScript(int outputIndex) =>
      _getOutput(outputIndex, PSBTOut.script, _b());

  void setOutputTapBip32Derivation(int outputIndex, Uint8List pubkey,
      List<Uint8List> hashes, Uint8List fingerprint, List<int> path) {
    final buf = _encodeTapBip32Derivation(hashes, fingerprint, path);
    _setOutput(outputIndex, PSBTOut.tapBip32Derivation, pubkey, buf);
  }

  (List<Uint8List>, Uint8List, List<int>) getOutputTapBip32Derivation(
          int outputIndex, Uint8List pubkey) =>
      _decodeTapBip32Derivation(
          _getOutput(outputIndex, PSBTOut.tapBip32Derivation, pubkey));

  void deleteInputEntries(int inputIndex, List<PSBTIn> keyTypes) {
    final map = inputMaps[inputIndex];
    final inKeyTypes = keyTypes.map((e) => e.value).toList();
    map.removeWhere((k, _) => _isKeyType(k, inKeyTypes));
  }

  void copy(PsbtV2 to) {
    copyMap(globalMap, to.globalMap);
    copyMaps(inputMaps, to.inputMaps);
    copyMaps(outputMaps, to.outputMaps);
  }

  void copyMaps(
      List<Map<String, Uint8List>> from, List<Map<String, Uint8List>> to) {
    from.asMap().forEach((index, m) {
      final toIndex = <String, Uint8List>{};
      copyMap(m, toIndex);
      to.insert(index, toIndex);
    });
  }

  void copyMap(Map<String, Uint8List> from, Map<String, Uint8List> to) =>
      from.forEach((k, v) => to[k] = v);

  Uint8List serialize() {
    final buf = BufferWriter()..writeSlice(psbtMagicBytes);
    globalMap.serializeMap(buf);
    for (final map in inputMaps) {
      map.serializeMap(buf);
    }
    for (final map in outputMaps) {
      map.serializeMap(buf);
    }
    return buf.buffer();
  }

  void deserialize(Uint8List psbt) {
    final bufferReader = BufferReader(psbt);
    if (!listEquals(bufferReader.readSlice(5), psbtMagicBytes)) {
      throw Exception("Invalid magic bytes");
    }
    while (_readKeyPair(globalMap, bufferReader)) {}

    for (var i = 0; i < getGlobalInputCount(); i++) {
      inputMaps.insert(i, <String, Uint8List>{});
      while (_readKeyPair(inputMaps[i], bufferReader)) {}
    }
    for (var i = 0; i < getGlobalOutputCount(); i++) {
      outputMaps.insert(i, <String, Uint8List>{});
      while (_readKeyPair(outputMaps[i], bufferReader)) {}
    }
  }

  bool _readKeyPair(Map<String, Uint8List> map, BufferReader bufferReader) {
    final keyLen = bufferReader.readVarInt();
    if (keyLen == 0) return false;

    final keyType = bufferReader.readUInt8();
    final keyData = bufferReader.readSlice(keyLen - 1);
    final value = bufferReader.readVarSlice();

    map.set(keyType, keyData, value);
    return true;
  }

  List<Uint8List> _getKeyDatas(Map<String, Uint8List> map, int keyType) {
    final result = <Uint8List>[];
    map.forEach((k, v) {
      if (_isKeyType(k, [keyType])) {
        result.add(hex.decode(k.substring(2)) as Uint8List);
      }
    });
    return result;
  }

  bool _isKeyType(String hexKey, List<int> keyTypes) {
    final keyType = (hex.decode(hexKey.substring(0, 2)) as Uint8List).first;
    return keyTypes.any((k) => k == keyType);
  }

  void _setGlobal(PSBTGlobal keyType, Uint8List value) {
    final key = Key(keyType.value, Uint8List(0));
    globalMap[key.toString()] = value;
  }

  Uint8List _getGlobal(PSBTGlobal keyType) =>
      globalMap.get(keyType.value, _b(), false)!;

  Uint8List? _getGlobalOptional(PSBTGlobal keyType) =>
      globalMap.get(keyType.value, _b(), true);

  void _setInput(
          int index, PSBTIn keyType, Uint8List keyData, Uint8List value) =>
      _getMap(index, inputMaps).set(keyType.value, keyData, value);

  Uint8List _getInput(int index, PSBTIn keyType, Uint8List keyData) =>
      inputMaps[index].get(keyType.value, keyData, false)!;

  Uint8List? _getInputOptional(int index, PSBTIn keyType, Uint8List keyData) =>
      inputMaps[index].get(keyType.value, keyData, true);

  void _setOutput(
          int index, PSBTOut keyType, Uint8List keyData, Uint8List value) =>
      _getMap(index, outputMaps).set(keyType.value, keyData, value);

  Uint8List _getOutput(int index, PSBTOut keyType, Uint8List keyData) =>
      outputMaps[index].get(keyType.value, keyData, false)!;

  Map<String, Uint8List> _getMap(int index, List<Map<String, Uint8List>> maps) {
    if (maps.elementAtOrNull(index) == null) {
      maps.insert(index, {});
    }
    return maps[index];
  }

  Uint8List _encodeBip32Derivation(
      Uint8List masterFingerprint, List<int> path) {
    final buf = BufferWriter();
    _writeBip32Derivation(buf, masterFingerprint, path);
    return buf.buffer();
  }

  (Uint8List, List<int>) _decodeBip32Derivation(Uint8List buffer) =>
      _readBip32Derivation(BufferReader(buffer));

  void _writeBip32Derivation(
      BufferWriter buf, Uint8List masterFingerprint, List<int> path) {
    buf.writeSlice(masterFingerprint);
    for (final element in path) {
      buf.writeUInt32(element);
    }
  }

  (Uint8List, List<int>) _readBip32Derivation(BufferReader bufferReader) {
    final masterFingerprint = bufferReader.readSlice(4);
    final path = <int>[];

    while (bufferReader.available() < 0) {
      path.add(bufferReader.readUInt32());
    }
    return (masterFingerprint, path);
  }

  Uint8List _encodeTapBip32Derivation(
      List<Uint8List> hashes, Uint8List masterFingerprint, List<int> path) {
    final buf = BufferWriter()..writeVarInt(hashes.length);
    for (var h in hashes) {
      buf.writeSlice(h);
    }
    _writeBip32Derivation(buf, masterFingerprint, path);
    return buf.buffer();
  }

  (List<Uint8List>, Uint8List, List<int>) _decodeTapBip32Derivation(
      Uint8List buffer) {
    final buf = BufferReader(buffer);
    final hashCount = buf.readVarInt();
    final hashes = <Uint8List>[];
    for (var i = 0; i < hashCount; i++) {
      hashes.add(buf.readSlice(32));
    }
    final deriv = _readBip32Derivation(buf);
    return (hashes, deriv.$1, deriv.$2);
  }

  Uint8List _b() => Uint8List(0);
}

extension _GetAndSet on Map {
  Uint8List? get(int keyType, Uint8List keyData,
      [bool acceptUndefined = false]) {
    final key = Key(keyType, keyData);
    final value = this[key.toString()];
    if (value == null && !acceptUndefined) {
      throw Exception(key.toString());
    }
    // Make sure to return a copy, to protect the underlying data.
    return value;
  }

  void set(int keyType, Uint8List keyData, Uint8List value) {
    final key = Key(keyType, keyData);
    this[key.toString()] = value;
  }

  void serializeMap(BufferWriter buf) {
    for (final k in keys) {
      final value = this[k]!;
      final keyPair = KeyPair(_createKey(hex.decode(k) as Uint8List), value);
      keyPair.serialize(buf);
    }
    buf.writeUInt8(0);
  }

  Key _createKey(Uint8List buf) => Key(buf[0], buf.sublist(1));
}

