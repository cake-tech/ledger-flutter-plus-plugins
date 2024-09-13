import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/ledger/litecoin_instructions.dart';
import 'package:ledger_litecoin/src/utils/bip32_path_helper.dart';
import 'package:ledger_litecoin/src/utils/bip32_path_to_buffer.dart';

/// This command is used to sign message using a private key.
///
/// This command has been supported since firmware version 1.0.8
///
/// The input data is the message to sign, streamed to the device in 255 bytes maximum data chunks
class LitecoinSignMsgOperation extends LedgerOperation<Uint8List> {
  /// The [derivationPath] is a Bip32-path used to derive the public key/Address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  /// The [message] to sign is the magic "\x18Bitcoin Signed Message:\n" -
  /// followed by the length of the message to sign on 1 byte
  /// (if requested) followed by the binary content of the message
  final Uint8List message;

  LitecoinSignMsgOperation(this.message, this.derivationPath);

  // The signature is returned using the standard ASN-1 encoding.
  // To convert it to the proprietary Bitcoin-QT format, the host has to :
  //
  // Get the parity of the first byte (sequence) : P
  // Add 27 to P if the public key is not compressed, otherwise add 31 to P
  // Return the Base64 encoded version of P || r || s
  @override
  Future<Uint8List> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);

    // final v = response[0].toInt();
    // final r = response.sublist(1, 1 + 32).toHexString();
    // final s = response.sublist(1 + 32, 1 + 32 + 32).toHexString();

    return response;
  }

  Uint8List createNextChunk(int offset, int chunkSize) {
    final writer = ByteDataWriter()
      ..writeUint8(btcCLA)
      ..writeUint8(signMessageINS)
      ..writeUint8(0x80)
      ..writeUint8(0x80)
      ..writeUint8(chunkSize)
      ..write(message.sublist(offset, offset + chunkSize));

    return writer.toBytes();
  }

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    final outputs = <Uint8List>[];

    writer
      ..writeUint8(btcCLA)
      ..writeUint8(signMessageINS)
      ..writeUint8(0x00)
      ..writeUint8(0x01);

    final path = BIPPath.fromString(derivationPath).toPathArray();

    final dataWriter = ByteDataWriter()..write(packDerivationPath(path));

    var offset = 0;
    final firstChunkMaxSize = 150 - 1 - path.length - 4 * 4;
    final firstChunkSize = offset + firstChunkMaxSize > message.length
        ? message.length
        : firstChunkMaxSize;

    // Write first chunk
    dataWriter.writeUint16(message.length);
    dataWriter.write(message.sublist(0, firstChunkSize));

    final dataBy = dataWriter.toBytes();
    writer.writeUint8(dataBy.length);
    writer.write(dataBy);

    outputs.add(writer.toBytes());

    offset = firstChunkSize;


    print(message.length);
    print(firstChunkSize);
    print(offset);
    while (offset < message.length) {
      final chunkSize =
          offset + 150 > message.length ? message.length - offset : 150;

      outputs.add(createNextChunk(offset, chunkSize));
      offset += chunkSize;
    }

    final endOutput = ByteDataWriter()
      ..writeUint8(btcCLA)
      ..writeUint8(signMessageINS)
      ..writeUint8(0x80)
      ..writeUint8(0x00)
      ..writeUint8(0x00);

    outputs.add(endOutput.toBytes());

    return outputs;
  }
}
