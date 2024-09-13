import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/ledger/ledger_input_operation.dart';
import 'package:ledger_litecoin/src/ledger/litecoin_instructions.dart';

/// This command is used to extract a Trusted Input (encrypted transaction hash,
/// output index, output amount) from a transaction.
///
/// The transaction data to be provided should be encoded using bitcoin standard
/// raw transaction encoding. Scripts can be sent over several APDUs.
/// Other individual transaction elements split over different APDUs will be
/// rejected. 64 bits varints are rejected.
class LitecoinGetTrustedInputOperation extends LedgerInputOperation<Uint8List> {
  final int? indexLookup;

  final Uint8List inputData;

  LitecoinGetTrustedInputOperation(this.inputData, [this.indexLookup])
      : super(btcCLA, getTrustedInputINS);

  @override
  int get p1 => indexLookup != null ? 0x00 : 0x80;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> read(ByteDataReader reader) async {
    final result = reader.read(reader.remainingLength);

    return result.isNotEmpty ? result.sublist(0, result.length - 2) : result;
  }

  @override
  Future<Uint8List> writeInputData() async {
    final writer = ByteDataWriter();
    if (indexLookup != null) writer.writeUint32(indexLookup!, Endian.big);

    writer.write(inputData);

    return writer.toBytes();
  }
}
