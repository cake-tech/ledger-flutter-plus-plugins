import 'dart:typed_data';

import 'package:dart_varuint_bitcoin/dart_varuint_bitcoin.dart' as varint;
import 'package:ledger_litecoin/src/tx_utils/transaction.dart';

Uint8List serializeWitness(List<Uint8List> witness) {
  var witnessBuffer =
      witness.isNotEmpty ? varint.encode(witness.length).buffer : Uint8List(0);

  for (final wit in witness) {
    witnessBuffer = Uint8List.fromList([
      ...witnessBuffer,
      ...varint.encode(wit.length).buffer,
      ...wit,
    ]);
  }

  return witnessBuffer;
}

Uint8List serializeTransactionOutputs(List<TransactionOutput> outputs) {
  var outputBuffer =
      outputs.isNotEmpty ? varint.encode(outputs.length).buffer : Uint8List(0);

  for (final output in outputs) {
    outputBuffer = Uint8List.fromList([
      ...outputBuffer,
      ...output.amount,
      ...varint.encode(output.script.length).buffer,
      ...output.script,
    ]);
  }

  return outputBuffer;
}

Uint8List serializeTransaction(Transaction transaction, bool skipWitness,
    [bool isBech32 = false]) {
  final useWitness = transaction.witness != null && !skipWitness;

  var inputBuffer = Uint8List(0);

  for (final input in transaction.inputs) {
    inputBuffer = isBech32
        ? Uint8List.fromList([
            ...inputBuffer,
            ...input.prevout,
            0x00,
            ...input.sequence,
          ])
        : Uint8List.fromList([
            ...inputBuffer,
            ...input.prevout,
            ...varint.encode(input.script.length).buffer,
            ...input.script,
            ...input.sequence,
          ]);
  }

  var outputBuffer = serializeTransactionOutputs(transaction.outputs);

  if (transaction.outputs.isNotEmpty && transaction.locktime != null) {
    outputBuffer = Uint8List.fromList([
      ...outputBuffer,
      ...(useWitness ? serializeWitness(transaction.witness!) : Uint8List(0)),
      ...transaction.locktime ?? Uint8List(0)
    ]);
  }

  return Uint8List.fromList([
    ...transaction.version,
    ...(useWitness ? [0x00, 0x01] : Uint8List(0)),
    ...varint.encode(transaction.inputs.length).buffer,
    ...inputBuffer,
    ...outputBuffer,
  ]);
}
