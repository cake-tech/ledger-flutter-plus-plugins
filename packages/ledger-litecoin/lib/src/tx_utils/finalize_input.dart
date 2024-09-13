import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/ledger/litecoin_instructions.dart';
import 'package:ledger_litecoin/src/tx_utils/constants.dart';
import 'package:ledger_litecoin/src/operations/litecoin_untrusted_hash_tx_input_finalize_operation.dart';
import 'package:ledger_litecoin/src/utils/string_uint8list_extension.dart';
import 'package:logging/logging.dart' as logging;

Future<Uint8List> provideOutputFullChangePath(
        LedgerConnection connection, LedgerTransformer transformer,
        {required String path}) =>
    connection.sendOperation(
        LitecoinUntrustedHashTxInputFinalizeOperation(derivationPath: path),
        transformer: transformer);

Future<Uint8List> hashOutputFull(
    LedgerConnection connection, LedgerTransformer transformer,
    {required Uint8List outputScript}) async {
  var offset = 0;
  final responses = <Uint8List>[];
  final outputScriptLength = outputScript.length;
  while (offset < outputScriptLength) {
    final blockSize = offset + MAX_SCRIPT_BLOCK >= outputScriptLength
        ? outputScriptLength - offset
        : MAX_SCRIPT_BLOCK;

    final p1 = offset + blockSize == outputScriptLength ? 0x80 : 0x00;
    final data = outputScript.sublist(offset, offset + blockSize);

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

  Uint8List? finalRes;
  for (final res in responses) {
    finalRes = await connection.sendOperation(RawOperation(data: res),
        transformer: transformer);
  }

  return finalRes!;
}

class RawOperation extends LedgerOperation<Uint8List> {
  final Uint8List data;

  RawOperation({required this.data});

  @override
  Future<Uint8List> read(ByteDataReader reader) async =>
      reader.read(reader.remainingLength);

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    logging.Logger.root.log(logging.Level.INFO,
        '[Ledger][${runtimeType.toString()}] => ${data.toPaddedHexString()}');
    return [data];
  }
}
