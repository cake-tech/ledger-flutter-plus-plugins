import 'dart:typed_data';

/// Convert a bigint into a little endian unsigned 64 bit Uint8List
List<int> bigIntToUint64LE(BigInt bigInt,
    {int length = 8, Endian order = Endian.little}) {
  final bigMaskEight = BigInt.from(0xff);
  if (bigInt == BigInt.zero) return List.filled(length, 0);

  var byteList = List<int>.filled(length, 0);
  for (var i = 0; i < length; i++) {
    byteList[length - i - 1] = (bigInt & bigMaskEight).toInt();
    bigInt = bigInt >> 8;
  }

  if (order == Endian.little) byteList = byteList.reversed.toList();

  return List<int>.from(byteList);
}
