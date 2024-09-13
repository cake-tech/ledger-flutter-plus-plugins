import 'dart:convert';

import 'package:ledger_bitcoin/src/psbt/psbtv2.dart';
import 'package:test/test.dart';

void main() {
  group('PsbtV2', () {
    test("deserializes a psbt and reserializes it unchanged", () {
      final psbtBuf = base64.decode(
          "cHNidP8BAJoCAAAAAljoeiG1ba8MI76OcHBFbDNvfLqlyHV5JPVFiHuyq911AAAAAAD/////g40EJ9DsZQpoqka7CwmK6kQiwHGyyng1Kgd5WdB86h0BAAAAAP////8CcKrwCAAAAAAWABSve4dsqS9Jy3P29AFb+ojLwuDoZwDh9QUAAAAAFgAUp2rS6ZK5wEZWSXYylPoeCj/Rr/EAAAAAAAAAAAA=");

      final psbt = PsbtV2();
      psbt.deserialize(psbtBuf);

      expect(psbtBuf, psbt.serialize());
    });
  });
}
