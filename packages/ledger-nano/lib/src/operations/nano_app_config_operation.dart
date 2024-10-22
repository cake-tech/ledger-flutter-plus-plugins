import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:ledger_nano/src/ledger/nano_instructions.dart';
import 'package:ledger_nano/src/nano_app_config.dart';
import 'package:ledger_nano/src/utils/string_uint8list_extension.dart';

/// This command returns specific application configuration
class NanoAppConfigOperation extends LedgerRawOperation<NanoAppConfig> {
  final bool display = false;

  @override
  Future<NanoAppConfig> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);

    var i = 0;
    final majorVersion = response[i++];
    final minorVersion = response[i++];
    final patchVersion = response[i++];
    final coinNameLength = response[i++];
    final coinName = response.sublist(i, i + coinNameLength).toAsciiString();

    return NanoAppConfig(majorVersion, minorVersion, patchVersion, coinName);
  }

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer
      ..writeUint8(nanoCLA)
      ..writeUint8(appConfigurationINS)
      ..writeUint8(0x00)
      ..writeUint8(0x00);

    return [writer.toBytes()];
  }
}
