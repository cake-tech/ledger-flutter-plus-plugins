import 'dart:typed_data';

import 'package:ledger_bitcoin/src/ledger/ledger_input_operation.dart';
import 'package:ledger_bitcoin/src/utils/int_extension.dart';
import 'package:ledger_bitcoin/src/wallet_policy.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class BitcoinSignPsbtOperation extends LedgerInputOperation<Uint8List> {
  final WalletPolicy walletPolicy;
  final Uint8List? walletHMAC;

  final int inputCount;
  final int outputCount;

  final Uint8List globalKeysValuesRoot;
  final Uint8List inputsMapsRoot;
  final Uint8List outputsMapsRoot;

  BitcoinSignPsbtOperation({
    required this.walletPolicy,
    required this.globalKeysValuesRoot,
    required this.inputCount,
    required this.inputsMapsRoot,
    required this.outputCount,
    required this.outputsMapsRoot,
    this.walletHMAC,
  }) : super(0xE1, 0x04);

  @override
  Future<Uint8List> read(ByteDataReader reader) async =>
      reader.read(reader.remainingLength);

  @override
  int get p1 => 0x00;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> writeInputData() async {
    final walletHMACBytes = walletHMAC ?? Uint8List(32);

    final writer = ByteDataWriter()
      ..write(globalKeysValuesRoot)
      ..write(inputCount.toVarint())
      ..write(inputsMapsRoot)
      ..write(outputCount.toVarint())
      ..write(outputsMapsRoot)
      ..write(walletPolicy.id)
      ..write(walletHMACBytes);

    return writer.toBytes();
  }
}
