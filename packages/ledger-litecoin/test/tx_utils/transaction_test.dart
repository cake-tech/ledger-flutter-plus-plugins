import 'package:ledger_litecoin/ledger_litecoin.dart';
import 'package:test/test.dart';

void main() {
  group('Transaction', () {
    test('from raw', () {
      final txRaw =
          "010000000001018c055c85c3724c98842d27712771dd0de139711f5940bba2df4615c5522184740000000017160014faf7f6dfb4e70798b92c93f33b4c51024491829df0ffffff022b05c70000000000160014f489f947fd13a1fb44ac168427081d3f30b6ce0cde9dd82e0000000017a914d5eca376cb49d65031220ff9093b7d407073ed0d8702483045022100f648c9f6a9b8f35b6ec29bbfae312c95ed3d56ce6a3f177d994efe90562ec4bd02205b82ce2c94bc0c9d152c3afc668b200bd82f48d6a14e83c66ba0f154cd5f69190121038f1dca119420d4aa7ad04af1c0d65304723789cccc56d335b18692390437f35900000000";

      final actual = Transaction.fromRaw(txRaw);
      expect(actual.inputs.length, 1);
      expect(actual.outputs.length, 2);
    });
  });
}
