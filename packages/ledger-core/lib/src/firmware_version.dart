class FirmwareVersion {
  final int majorVersion;
  final int minorVersion;
  final int patchVersion;

  /// Possible [flags] are
  /// - 0x01 : public keys are compressed (otherwise not compressed)
  /// - 0x02 : implementation running with screen + buttons handled by the Secure Element
  /// - 0x04 : implementation running with screen + buttons handled externally
  /// - 0x08 : NFC transport and payment extensions supported
  /// - 0x10 : BLE transport and low power extensions supported
  /// - 0x20 : implementation running on a Trusted Execution Environment
  final int flag;

  final int architecture;

  FirmwareVersion(
    this.majorVersion,
    this.minorVersion,
    this.patchVersion,
    this.flag,
    this.architecture,
  );

  String get version => "$majorVersion.$minorVersion.$patchVersion";
}
