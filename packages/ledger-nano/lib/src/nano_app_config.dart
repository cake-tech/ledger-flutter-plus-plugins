class NanoAppConfig {
  final int majorVersion;
  final int minorVersion;
  final int patchVersion;
  final String coinName;

  NanoAppConfig(
      this.majorVersion, this.minorVersion, this.patchVersion, this.coinName);

  String get version => "$majorVersion.$minorVersion.$patchVersion";

  @override
  String toString() =>
      "NanoAppConfig(majorVersion=$majorVersion, minorVersion=$minorVersion, patchVersion=$patchVersion, coinName=$coinName)";
}
