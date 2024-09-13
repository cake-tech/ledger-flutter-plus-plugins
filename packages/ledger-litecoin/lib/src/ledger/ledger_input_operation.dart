import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/utils/string_uint8list_extension.dart';
import 'package:logging/logging.dart' as logging;

abstract class LedgerInputOperation<T> extends LedgerOperation<T> {
  final int cla;
  final int ins;

  LedgerInputOperation(this.cla, this.ins);

  int get p1;

  int get p2;

  Future<Uint8List> writeInputData();

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer
      ..writeUint8(cla)
      ..writeUint8(ins)
      ..writeUint8(p1)
      ..writeUint8(p2);

    final inputData = await writeInputData();
    writer
      ..writeUint8(inputData.length)
      ..write(inputData);

    logging.Logger.root.log(logging.Level.INFO,
        '[Ledger][${runtimeType.toString()}] => ${writer.toBytes().toPaddedHexString()}');
    return [writer.toBytes()];
  }
}
