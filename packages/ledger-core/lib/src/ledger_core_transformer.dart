import 'dart:typed_data';

import 'package:ledger_core/ledger_core.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_core/src/utils/string_uint8list_extension.dart';
import 'package:logging/logging.dart' as logging;

class LedgerCoreTransformer extends LedgerTransformer {
  const LedgerCoreTransformer();

  @override
  Future<Uint8List> onTransform(List<Uint8List> transform) async {
    logging.Logger.root.log(logging.Level.INFO,
        '[Ledger] <= ${transform.map((e) => e.toHexString())}');

    if (transform.isEmpty) {
      throw Exception('No response data from Ledger.');
    }

    final lastItem = transform.last;
    if (lastItem.length == 2) {
      final statusCode = lastItem.toPaddedHexString().toLowerCase();
      if (statusCode == '9000') return Uint8List(0);

      throw LedgerCoreException(statusCode: statusCode);
    }

    return Uint8List.fromList(transform.expand((e) => e).toList());
  }
}
