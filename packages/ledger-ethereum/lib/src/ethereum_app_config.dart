class EthereumAppConfig {
  final int majorVersion;
  final int minorVersion;
  final int patchVersion;

  /// Possible [flags] are
  /// - 0x01 : arbitrary data signature enabled by user
  /// - 0x02 : ERC 20 Token information needs to be provided externally
  final int flags;

  EthereumAppConfig(
      this.majorVersion, this.minorVersion, this.patchVersion, this.flags);

  String get version => "$majorVersion.$minorVersion.$patchVersion";
}
