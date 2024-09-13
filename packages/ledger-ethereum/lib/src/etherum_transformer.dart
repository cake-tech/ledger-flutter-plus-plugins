import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class EthereumTransformer extends LedgerTransformer {
  const EthereumTransformer();

  @override
  Future<Uint8List> onTransform(List<Uint8List> transform) async {
    if (transform.isEmpty) {
      throw Exception('No response data from Ledger.');
    }

    final lastItem = transform.last;
    if (lastItem.length == 2) {
      final errorCode = ByteData.sublistView(lastItem).getInt16(0);

      if (lastItem.first == 0x90 && lastItem.last == 0x00) {
        return Uint8List.fromList([]);
      }

      throw Exception(errorCode);
    }

    final output = <Uint8List>[];

    for (final data in transform) {
      final offset = (data.length >= 2) ? 2 : 0;
      output.add(data.sublist(0, data.length - offset));
    }

    return Uint8List.fromList(output.expand((e) => e).toList());
  }
}
