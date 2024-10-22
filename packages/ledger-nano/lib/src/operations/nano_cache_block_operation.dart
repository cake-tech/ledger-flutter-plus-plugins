import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:ledger_nano/src/ledger/ledger_input_operation.dart';
import 'package:ledger_nano/src/ledger/nano_instructions.dart';
import 'package:ledger_nano/src/utils/bip32_path_helper.dart';
import 'package:ledger_nano/src/utils/bip32_path_to_buffer.dart';

/// This command caches the frontier block in memory.
/// The sign block command uses this cached data to determine the changes in account state.
class NanoCacheBlockOperation extends LedgerInputOperation<Uint8List> {
  /// The [derivationPath] is a Bip32-path used to derive the address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  final String parentBlockhash;
  final String link;
  final String representative;
  final int balance;
  final String signature;

  NanoCacheBlockOperation({
    this.derivationPath = "m/44'/165'/0'",
    required this.parentBlockhash,
    required this.link,
    required this.representative,
    required this.balance,
    required this.signature,
  }) : super(nanoCLA, cacheBlockINS);

  @override
  Future<Uint8List> read(ByteDataReader reader) async =>
      reader.read(reader.remainingLength);

  @override
  int get p1 => 0x00;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> writeInputData() async {
    final writer = ByteDataWriter();

    final path = BIPPath.fromString(derivationPath).toPathArray();
    writer.write(packDerivationPath(path));

    writer.write(hex.decode(parentBlockhash));
    writer.write(hex.decode(link));
    writer.write(hex.decode(representative));
    writer.writeUint16(balance);
    writer.write(hex.decode(signature));
    return writer.toBytes();
  }
}
