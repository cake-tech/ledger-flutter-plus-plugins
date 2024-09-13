import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';
import 'package:pointycastle/export.dart';

Uint8List sha256Hasher(List<int> input) =>
    Uint8List.fromList(sha256.convert(input).bytes);

Uint8List hashPublicKey(Uint8List buffer) =>
    RIPEMD160Digest().process(sha256Hasher(buffer));

Uint8List pointAddScalar(Uint8List A, Uint8List tweak, [bool compressed = true]) {
  final ECDomainParameters curve = ECCurve_secp256k1();
  final point = curve.curve.decodePoint(A);
  return (point! + (curve.G * BigInt.parse(tweak.toHexString(), radix: 16)))!.getEncoded(compressed);
}
