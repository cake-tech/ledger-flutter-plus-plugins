import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart';

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
  final bitcoinApp = BitcoinLedgerApp(connection);

  /// Fetch a list of accounts/public keys from your ledger.
  final accounts = await bitcoinApp.getAccounts();

  print(accounts);
}
