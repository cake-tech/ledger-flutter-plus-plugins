import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/tx_utils/serialize_transaction.dart';
import 'package:ledger_litecoin/src/tx_utils/transaction.dart';
import 'package:ledger_litecoin/src/utils/make_xpub.dart';
import 'package:ledger_litecoin/src/utils/string_uint8list_extension.dart';

String getTrustedInputBIP143(
  int indexLookup,
  Transaction transaction,
) {
  final hash = sha256(sha256(serializeTransaction(transaction, true)));

  final data = ByteDataWriter()..writeUint32(indexLookup, Endian.little);

  if (transaction.outputs.elementAtOrNull(indexLookup) == null) {
    throw Exception("getTrustedInputBIP143: wrong index");
  }

  return Uint8List.fromList([
    ...hash,
    ...data.toBytes(),
    ...transaction.outputs[indexLookup].amount
  ]).toHexString();
}
