import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/operations/litecoin_untrusted_hash_sign_operation.dart';

Future<Uint8List> signTransaction(
  LedgerConnection connection,
  LedgerTransformer transformer, {
  required String path,
  required int lockTime,
  required int sigHashType,
}) =>
    connection.sendOperation(
        LitecoinUntrustedHashSignOperation(path, lockTime, sigHashType),
        transformer: transformer);
