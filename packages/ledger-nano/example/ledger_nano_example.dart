import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_nano/ledger_nano.dart';

Future<void> main() async {
  /// Create a new instance of LedgerOptions.
  final ledgerBle = LedgerInterface.ble(
    onPermissionRequest: (_) async => true,
  );

  /// Scan for devices
  ledgerBle.scan().listen((device) => print(device));

  /// or get a connected one
  final device = (await ledgerBle.devices).first;

  final connection = await ledgerBle.connect(device);

  /// Create a new Bitcoin Ledger Plugin.
  final nanoApp = NanoLedgerApp(connection);

  /// Fetch a list of accounts/public keys from your ledger.
  final accounts = await nanoApp.getAccounts();

  print(accounts);
}
