import 'dart:typed_data';

import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:pointycastle/pointycastle.dart';

String makeXpub(int version, List<int> derivationPath, Uint8List chainCode,
    Uint8List publicKey) {
  final buffer = Uint8List(78);
  final bytes = buffer.buffer.asByteData();

  final parentFingerprint =
      ripemd160(compressPublicKeySECP256(publicKey)).sublist(0, 4);

  bytes.setUint32(0, version);
  bytes.setUint8(4, derivationPath.length);
  buffer.setRange(5, 9, parentFingerprint);
  bytes.setUint32(9, derivationPath.last);
  buffer.setRange(13, 45, chainCode);
  buffer.setRange(45, 78, compressPublicKeySECP256(publicKey));

  return bs58check.encode(buffer);
}

Uint8List ripemd160(Uint8List a) => Digest('RIPEMD-160').process(a);

Uint8List sha256(Uint8List a) => Digest("SHA-256").process(a);

Uint8List compressPublicKeySECP256(Uint8List publicKey) => Uint8List.fromList([
      ...Uint8List.fromList([0x02 + (publicKey[64] & 0x01)]),
      ...publicKey.sublist(1, 33)
    ]);

Uint8List hashPublicKey(Uint8List buffer) => ripemd160(sha256((buffer)));
