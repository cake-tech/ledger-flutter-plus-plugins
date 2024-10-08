import 'dart:convert';

import 'package:ledger_bitcoin/src/psbt/psbtv2.dart';
import 'package:test/test.dart';

void main() {
  group('PsbtV2', () {
    test("deserialize a psbt", () {
      final psbtBuf = base64.decode(
          "cHNidP8BAgQCAAAAAQQBAQEFAQIB+wQCAAAAAAEOIAsK2SFBnByHGXNdctxzn56p4GONH+TB7vD5lECEgV/IAQ8EAAAAAAABAwgACK8vAAAAAAEEFgAUxDD2TEdW2jENvRoIVXLvKZkmJywAAQMIi73rCwAAAAABBBYAFE3Rk6yWSlasG54cyoRU/i9HT4UTAA==");

      final psbt = PsbtV2();
      psbt.deserialize(psbtBuf);

      expect(psbt.getGlobalInputCount(), 1);
      expect(psbt.getGlobalOutputCount(), 2);
    });
  });
}
