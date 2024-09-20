import 'package:ledger_core/src/operations/ledger_open_app_operation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_core/src/firmware_version.dart';
import 'package:ledger_core/src/ledger_core_transformer.dart';
import 'package:ledger_core/src/operations/ledger_app_config_operation.dart';

class LedgerCore {
  final LedgerCoreTransformer transformer;
  final LedgerConnection connection;

  LedgerCore(
    this.connection, {
    this.transformer = const LedgerCoreTransformer(),
  });

  Future<FirmwareVersion> getFirmwareVersion() =>
      connection.sendOperation<FirmwareVersion>(
        LedgerAppConfigOperation(),
        transformer: transformer,
      );

  Future<bool> openApp(String appName) =>
      connection.sendOperation<bool>(
        LedgerOpenAppOperation(appName),
        transformer: transformer,
      );
}
