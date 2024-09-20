import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_core/ledger_core.dart';

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

  /// Create a new Core Ledger Plugin.
  final coreApp = LedgerCore(connection);

  /// Fetch the firmware version
  final version = await coreApp.getFirmwareVersion();

  print(version);
}
