import 'package:ledger_ethereum/src/utils/bip32_path_helper.dart';
import 'package:test/test.dart';

void main() {
  group('BIP32Path', () {
    test('from PathArray', () {
      final actual = BIPPath.fromPathArray([0x8000002c, 1, 1, 0]).toString();
      expect(actual, "m/44'/1/1/0");
    });

    test('fromString to old style string', () {
      final actual = BIPPath.fromString("m/44'/0'/0'").toString(oldStyle: true);
      expect(actual, "m/44h/0h/0h");
    });

    test('fromString to no root string', () {
      final actual = BIPPath.fromString("m/44h/0h/0'").toString(noRoot: true);
      expect(actual, "44'/0'/0'");
    });

    test('fromString to PathArray', () {
      final actual = BIPPath.fromString("m/44'/0'/0'").toPathArray();
      expect(actual, [ 0x8000002c, 0x80000000, 0x80000000 ]);
    });

    test('fromString to PathArray', () {
      final actual = BIPPath.fromString("m/44'/1/1/0").toPathArray();
      expect(actual, [0x8000002c, 1, 1, 0]);
    });
  });
}
