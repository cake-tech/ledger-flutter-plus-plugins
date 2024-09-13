import 'dart:typed_data';

import 'package:dart_varuint_bitcoin/dart_varuint_bitcoin.dart' as varint;
import 'package:flutter/foundation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/operations/litecoin_untrusted_hash_tx_input_start_operation.dart';
import 'package:ledger_litecoin/src/tx_utils/constants.dart';
import 'package:ledger_litecoin/src/tx_utils/create_transaction.dart';
import 'package:ledger_litecoin/src/tx_utils/transaction.dart';

Future<void> startUntrustedHashTransactionInput(
    LedgerConnection connection, LedgerTransformer transformer,
    {required bool isNewTransaction,
    required Transaction transaction,
    required List<TrustedInput> inputs,
    bool isBip143 = false,
    List<String> additionals = const [],
    bool useTrustedInputForSegwit = false}) async {
  var data = ByteDataWriter()
    ..write(transaction.version)
    ..write(varint.encode(transaction.inputs.length).buffer);

  await connection.sendOperation(
      LitecoinUntrustedHashTxInputStartOperation(
        isNewTransaction,
        true,
        data.toBytes(),
        isBip143,
        additionals.contains("cashaddr"),
      ),
      transformer: transformer);

  var i = 0;

  for (final input in transaction.inputs) {
    late final Uint8List prefix;
    if (isBip143) {
      if (useTrustedInputForSegwit && inputs[i].trustedInput) {
        prefix = Uint8List.fromList([0x01, inputs[i].value.length]);
      } else {
        prefix = Uint8List.fromList([0x02]);
      }
    } else {
      if (inputs[i].trustedInput) {
        prefix = Uint8List.fromList([0x01, inputs[i].value.length]);
      } else {
        prefix = Uint8List.fromList([0x00]);
      }
    }

    final data = Uint8List.fromList([
      ...prefix,
      ...inputs[i].value,
      ...varint.encode(input.script.length).buffer,
    ]);

    await connection.sendOperation(
        LitecoinUntrustedHashTxInputStartOperation(
          isNewTransaction,
          false,
          data,
          isBip143,
          additionals.contains("cashaddr"),
        ),
        transformer: transformer);

    final scriptBlocks = <Uint8List>[];
    var offset = 0;

    if (input.script.isEmpty) {
      scriptBlocks.add(input.sequence);
    } else {
      while (offset != input.script.length) {
        final blockSize = input.script.length - offset > MAX_SCRIPT_BLOCK
            ? MAX_SCRIPT_BLOCK
            : input.script.length - offset;

        if (offset + blockSize != input.script.length) {
          scriptBlocks.add(input.script.sublist(offset, offset + blockSize));
        } else {
          scriptBlocks.add(
            Uint8List.fromList([
              ...input.script.sublist(offset, offset + blockSize),
              ...input.sequence
            ]),
          );
        }

        offset += blockSize;
      }
    }

    for (final scriptBlock in scriptBlocks) {
      await connection.sendOperation(
          LitecoinUntrustedHashTxInputStartOperation(
            isNewTransaction,
            false,
            scriptBlock,
            isBip143,
            additionals.contains("cashaddr"),
          ),
          transformer: transformer);
    }

    i++;
  }
}
