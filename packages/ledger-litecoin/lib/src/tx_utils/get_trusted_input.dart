import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:dart_varuint_bitcoin/dart_varuint_bitcoin.dart' as varint;
import 'package:flutter/foundation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/operations/litecoin_get_trusted_input_operation.dart';
import 'package:ledger_litecoin/src/tx_utils/constants.dart';
import 'package:ledger_litecoin/src/tx_utils/transaction.dart';

Future<String> getTrustedInput(
    LedgerConnection connection, LedgerTransformer transformer,
    {required int indexLookup, required Transaction transaction}) async {
  Future<Uint8List> processScriptBlocks(
      Uint8List script, Uint8List? sequence) async {
    final seq = sequence ?? Uint8List(0);
    final scriptBlocks = <Uint8List>[];
    var offset = 0;

    while (offset != script.length) {
      final blockSize = script.length - offset > MAX_SCRIPT_BLOCK
          ? MAX_SCRIPT_BLOCK
          : script.length - offset;

      if (offset + blockSize != script.length) {
        scriptBlocks.add(script.sublist(offset, offset + blockSize));
      } else {
        scriptBlocks.add(Uint8List.fromList(
            [...script.sublist(offset, offset + blockSize), ...seq]));
      }

      offset += blockSize;
    }

    // Handle case when no script length: we still want to pass the sequence
    // relatable: https://github.com/LedgerHQ/ledger-live-desktop/issues/1386
    if (script.isEmpty) scriptBlocks.add(seq);

    Uint8List res = Uint8List(0);

    for (final scriptBlock in scriptBlocks) {
      res = await connection.sendOperation(
          LitecoinGetTrustedInputOperation(scriptBlock),
          transformer: transformer);
    }

    return res;
  }

  await connection.sendOperation(
      LitecoinGetTrustedInputOperation(
        Uint8List.fromList([
          ...transaction.version,
          ...varint.encode(transaction.inputs.length).buffer
        ]),
        indexLookup,
      ),
      transformer: transformer);

  for (final input in transaction.inputs) {
    final data = Uint8List.fromList(
        [...input.prevout, ...varint.encode(input.script.length).buffer]);

    await connection.sendOperation(LitecoinGetTrustedInputOperation(data),
        transformer: transformer);

    await processScriptBlocks(input.script, input.sequence);
  }

  await connection.sendOperation(
      LitecoinGetTrustedInputOperation(
          varint.encode(transaction.outputs.length).buffer),
      transformer: transformer);

  for (final output in transaction.outputs) {
    final data = Uint8List.fromList([
      ...output.amount,
      ...varint.encode(output.script.length).buffer,
      ...output.script,
    ]);
    await connection.sendOperation(LitecoinGetTrustedInputOperation(data),
        transformer: transformer);
  }

  final res = await processScriptBlocks(
      transaction.locktime ?? Uint8List.fromList([0, 0, 0, 0]), null);

  return hex.encode(res);
}
