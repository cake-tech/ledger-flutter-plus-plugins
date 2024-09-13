import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/ledger/litecoin_instructions.dart';
import 'package:ledger_litecoin/src/tx_utils/constants.dart';
import 'package:ledger_litecoin/src/utils/bip32_path_helper.dart';
import 'package:ledger_litecoin/src/utils/bip32_path_to_buffer.dart';
import 'package:ledger_litecoin/src/utils/string_uint8list_extension.dart';
import 'package:logging/logging.dart' as logging;

/// This command is used to compose an opaque SHA-256 hash from the transaction outputs.
/// This command is rejected if all inputs advertised at the beginning of the
/// transaction have not been processed first.
///
/// Only standard output scripts are accepted :
///
/// Pay-to-PubkeyHash (OP_DUP OP_HASH160 [pubKeyHash] OP_EQUALVERIFY OP_CHECKSIG)
/// Pay-to-Script-Hash (OP_HASH160 [script hash] OP_EQUAL)
/// A single maximum 80 bytes OP_RETURN with a null value
/// A P2WPKH (00 [20 bytes]) or P2WSH (00 [30 bytes]) version 0 witness program
class LitecoinUntrustedHashTxInputFinalizeOperation
    extends LedgerOperation<Uint8List> {
  final String? derivationPath;

  final Uint8List? outputScript;

  LitecoinUntrustedHashTxInputFinalizeOperation(
      {this.derivationPath, this.outputScript}) {
    assert(derivationPath != null || outputScript != null);
  }

  @override
  Future<Uint8List> read(ByteDataReader reader) async =>
      reader.read(reader.remainingLength);

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    if (derivationPath != null) {
      writer
        ..writeUint8(btcCLA)
        ..writeUint8(untrustedHashTransactionInputFinalizeINS)
        ..writeUint8(0xFF)
        ..writeUint8(0x00);

      final path = BIPPath.fromString(derivationPath!).toPathArray();
      final inputData = packDerivationPath(path);
      writer
        ..writeUint8(inputData.length)
        ..write(inputData);

      logging.Logger.root.log(logging.Level.INFO,
          '[Ledger][${runtimeType.toString()}] => ${writer.toBytes().toPaddedHexString()}');
      return [writer.toBytes()];
    }

    var offset = 0;
    final responses = <Uint8List>[];
    final outputScriptLength = outputScript!.length;
    while (offset < outputScriptLength) {
      final blockSize = offset + MAX_SCRIPT_BLOCK >= outputScriptLength
          ? outputScriptLength - offset
          : MAX_SCRIPT_BLOCK;

      final p1 = offset + blockSize == outputScriptLength ? 0x80 : 0x00;
      final data = outputScript!.sublist(offset, offset + blockSize);

      final dataWriter = ByteDataWriter()
        ..writeUint8(btcCLA)
        ..writeUint8(untrustedHashTransactionInputFinalizeINS)
        ..writeUint8(p1)
        ..writeUint8(0x00)
        ..writeUint8(data.length)
        ..write(data);

      responses.add(dataWriter.toBytes());
      offset += blockSize;
    }

    print('$runtimeType ${responses.map((e) => e.toPaddedHexString())}');
    return responses;
  }
}
