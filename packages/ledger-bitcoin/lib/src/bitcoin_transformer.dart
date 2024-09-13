import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class BitcoinTransformer extends LedgerTransformer {
  const BitcoinTransformer();

  @override
  Future<Uint8List> onTransform(List<Uint8List> transform) async {
    if (transform.isEmpty) {
      throw Exception('No response data from Ledger.');
    }

    final lastItem = transform.last;
    if (lastItem.length == 2) {
      throw Exception(hex.encode(lastItem));
    }

    final output = <Uint8List>[];

    for (final data in transform) {
      final offset = (data.length >= 2) ? 2 : 0;
      output.add(data.sublist(0, data.length - offset));
    }

    return Uint8List.fromList(output.expand((e) => e).toList());
  }
}
