import 'dart:typed_data';

import 'package:ledger_ethereum/src/ethereum_app_config.dart';
import 'package:ledger_ethereum/src/ledger/ethereum_instructions.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

/// This command returns specific application configuration
class EthereumAppConfigOperation extends LedgerOperation<EthereumAppConfig> {
  final bool display = false;

  @override
  Future<EthereumAppConfig> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);

    var i = 0;
    final flags = response[i++];
    final majorVersion = response[i++];
    final minorVersion = response[i++];
    final patchVersion = response[i++];

    return EthereumAppConfig(majorVersion, minorVersion, patchVersion, flags);
  }

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer
      ..writeUint8(ethCLA)
      ..writeUint8(appConfigINS)
      ..writeUint8(0x00)
      ..writeUint8(0x00);

    return [writer.toBytes()];
  }
}
