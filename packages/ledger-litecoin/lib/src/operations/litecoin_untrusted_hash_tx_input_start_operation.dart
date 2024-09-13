import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/ledger/ledger_input_operation.dart';
import 'package:ledger_litecoin/src/ledger/litecoin_instructions.dart';

/// This command is used to sign a given secure hash using a private key (after
/// re-hashing it following the standard Bitcoin signing process) to finalize a
/// transaction input signing process.
///
/// This command will be rejected if the transaction signing state is not
/// consistent or if a user validation is required and the provided user
/// validation code is not correct.
class LitecoinUntrustedHashTxInputStartOperation
    extends LedgerInputOperation<Uint8List> {
  final bool firstRound;
  final bool isNewTransaction;
  final bool useCashaddr;
  final bool isBip143;

  final Uint8List transactionData;

  LitecoinUntrustedHashTxInputStartOperation(
      this.isNewTransaction, this.firstRound, this.transactionData,
      [this.isBip143 = false, this.useCashaddr = false])
      : super(btcCLA, untrustedHashTransactionInputStartINS);

  @override
  int get p1 => firstRound ? 0x00 : 0x80;

  @override
  int get p2 => isNewTransaction
      ? useCashaddr
          ? 0x03
          : isBip143
              ? 0x02
              : 0x00
      : 0x80;

  @override
  Future<Uint8List> read(ByteDataReader reader) async =>
      reader.read(reader.remainingLength);

  @override
  Future<Uint8List> writeInputData() async => transactionData;
}
