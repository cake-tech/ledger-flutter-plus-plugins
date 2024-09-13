import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ledger_litecoin/src/utils/bigint_helper.dart';
import 'package:ledger_litecoin/src/utils/buffer_reader.dart';

class Transaction {
// Each transaction is prefixed by a four-byte transaction version number
// which tells Bitcoin peers and miners which set of rules to use to validate it.
  Uint8List version;
  List<TransactionInput> inputs;
  List<TransactionOutput> outputs;

// locktime indicates the earliest time or earliest block when that transaction may
// be added to the block chain.
  Uint8List? locktime;
  List<Uint8List>? witness;

  Transaction({
    required this.version,
    this.inputs = const [],
    this.outputs = const [],
    this.locktime,
    this.witness,
  });

  factory Transaction.fromRaw(String rawHex) {
    final raw = Uint8List.fromList(hex.decode(rawHex));
    final reader = BufferReader(raw);

    final version = reader.readSlice(4);
    final bool hasSegWit;
    if (rawHex.substring(8, 12) == "0001") {
      reader.readSlice(2);
      hasSegWit = true;
    } else {
      hasSegWit = false;
    }

    final inputCount = reader.readVarInt();

    final inputs = <TransactionInput>[];

    for (var i = 0; i < inputCount; i++) {
      final prevout = reader.readSlice(36);
      final script = reader.readVarSlice();
      final sequence = reader.readSlice(4);

      inputs.add(TransactionInput(prevout, script, sequence));
    }

    final outputCount = reader.readVarInt();

    final outputs = <TransactionOutput>[];

    for (var i = 0; i < outputCount; i++) {
      final amount = reader.readSlice(8);
      final script = reader.readVarSlice();

      outputs.add(TransactionOutput(amount, script));
    }

    final witness = <Uint8List>[];
    if (hasSegWit) {
      final witnessCount = reader.readVarInt();

      for (var i = 0; i < witnessCount; i++) {
        witness.add(reader.readVarSlice());
      }
    }

    reader.offset = reader.buffer.length - 4;
    final locktime = reader.readSlice(4);

    return Transaction(
      version: version,
      inputs: inputs,
      outputs: outputs,
      locktime: locktime,
      witness: witness,
    );
  }

  Transaction clone() => Transaction(
        version: version,
        inputs: inputs.map((e) => e.clone()).toList(),
        outputs: outputs.map((e) => e.clone()).toList(),
        locktime: locktime,
        witness: witness,
      );
}

class TransactionInput {
  Uint8List prevout;
  Uint8List script;
  Uint8List sequence;
  Uint8List? tree;

  TransactionInput(this.prevout, this.script, this.sequence, [this.tree]);

  TransactionInput clone() => TransactionInput(prevout, script, sequence, tree);
}

class TransactionOutput {
  Uint8List amount;
  Uint8List script;

  TransactionOutput(this.amount, this.script);

  TransactionOutput.fromBigInt(BigInt amountRaw, this.script)
      : amount = Uint8List.fromList(bigIntToUint64LE(amountRaw));

  TransactionOutput clone() => TransactionOutput(amount, script);
}

class LedgerTransaction {
  final String rawTx;
  final int outputIndex;
  final Uint8List? redeemScript;
  final int? sequence;
  final String ownerDerivationPath;
  final Uint8List ownerPublicKey;


  const LedgerTransaction({
    required this.rawTx,
    required this.outputIndex,
    required this.ownerDerivationPath,
    required this.ownerPublicKey,
    this.redeemScript,
    this.sequence,
  });
}
