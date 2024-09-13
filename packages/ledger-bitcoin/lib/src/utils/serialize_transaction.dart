import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:dart_varuint_bitcoin/dart_varuint_bitcoin.dart' as varuint;
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';

class TransactionInput {
  final Uint8List prevout;
  final Uint8List script;
  final Uint8List sequence;
  final Uint8List? tree;

  TransactionInput(this.prevout, this.script, this.sequence, this.tree);
}

class TransactionOutput {
  final Uint8List amount;
  final Uint8List script;

  TransactionOutput(this.amount, this.script);
}

class Transaction {
  final Uint8List version;
  final List<TransactionInput> inputs;
  final List<TransactionOutput>? outputs;
  final Uint8List? locktime;
  final Uint8List? witness;
  final Uint8List? timestamp;
  final Uint8List? nVersionGroupId;
  final Uint8List? nExpiryHeight;
  final Uint8List? extraData;

  Transaction(
      this.version,
      this.inputs,
      this.outputs,
      this.locktime,
      this.witness,
      this.timestamp,
      this.nVersionGroupId,
      this.nExpiryHeight,
      this.extraData);
}

Uint8List serializeTransactionOutputs(List<TransactionOutput> outputs) {
  var outputBuffer = varuint.encode(outputs.length).buffer;
  for (final output in outputs) {
    outputBuffer = joinUint8Lists([
      outputBuffer,
      output.amount,
      varuint.encode(output.script.length).buffer,
      output.script,
    ]);
  }

  return outputBuffer;
}

Uint8List serializeTransaction(Transaction transaction, bool skipWitness,
    [Uint8List? timestamp, List<String> additionals = const []]) {
  final isBech32 = additionals.contains("bech32");
  var inputBuffer = Uint8List(0);
  final useWitness = transaction.witness != null && !skipWitness;
  for (final input in transaction.inputs) {
    inputBuffer = isBech32
        ? joinUint8Lists([
            inputBuffer,
            input.prevout,
            Uint8List.fromList([0x00]), //tree
            input.sequence,
          ])
        : joinUint8Lists([
            inputBuffer,
            input.prevout,
            varuint.encode(input.script.length).buffer,
            input.script,
            input.sequence,
          ]);
  }
  var outputBuffer = serializeTransactionOutputs(transaction.outputs!);

  if (transaction.outputs != null && transaction.locktime != null) {
    outputBuffer = joinUint8Lists([
      outputBuffer,
      useWitness ? transaction.witness! : Uint8List(0),
      transaction.locktime ?? Uint8List(0),
      transaction.nExpiryHeight ?? Uint8List(0),
      transaction.extraData ?? Uint8List(0),
    ]);
  }

  return joinUint8Lists([
    transaction.version,
    timestamp ?? Uint8List(0),
    transaction.nVersionGroupId ?? Uint8List(0),
    useWitness ? Uint8List.fromList(hex.decode("0001")) : Uint8List(0),
    varuint.encode(transaction.inputs.length).buffer,
    inputBuffer,
    outputBuffer,
  ]);
}
