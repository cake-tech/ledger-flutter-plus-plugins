class CoinVersion {
  final String prefixP2PKH;
  final String prefixP2SH;

  final int coinFamily;

  final String coinName;
  final String coinTicker;

  CoinVersion(
    this.prefixP2PKH,
    this.prefixP2SH,
    this.coinFamily,
    this.coinName,
    this.coinTicker,
  );
}
