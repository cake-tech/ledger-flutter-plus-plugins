import 'dart:typed_data';

class LedgerAppVersion {
  final String name;
  final String version;
  final Uint8List flags;

  LedgerAppVersion(this.name, this.version, this.flags);
}
