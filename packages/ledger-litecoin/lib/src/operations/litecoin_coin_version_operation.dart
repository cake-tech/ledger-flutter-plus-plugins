import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/coin_version.dart';
import 'package:ledger_litecoin/src/ledger/litecoin_instructions.dart';
import 'package:ledger_litecoin/src/utils/string_uint8list_extension.dart';

/// This command returns the name of the current app, its ticker, its P2PKH and P2SH prefixes and its coin family
class LitecoinCoinVersionOperation extends LedgerOperation<CoinVersion> {
  @override
  Future<CoinVersion> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);

    final prefixP2PKH = response.sublist(0, 2).toAsciiString();
    final prefixP2SH = response.sublist(2, 4).toAsciiString();
    final coinFamily = response[4];

    final lengthCoinName = response[5];
    final coinName = response.sublist(5 + 1, 5 + 1 + lengthCoinName).toAsciiString();

    final lengthCoinTicker = response[5 + 1 + lengthCoinName];
    final coinTicker = response
        .sublist(5 + 1 + 1 + lengthCoinName, 5 + 1 + 1 + lengthCoinName + lengthCoinTicker)
        .toAsciiString();

    return CoinVersion(
        prefixP2PKH, prefixP2SH, coinFamily, coinName, coinTicker);
  }

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer..writeUint8(btcCLA)..writeUint8(getCoinVersionINS)..writeUint8(0x00)..writeUint8(
        0x00)..writeUint8(0x00);

    return [writer.toBytes()];
  }
}
