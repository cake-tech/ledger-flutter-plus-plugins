enum AddressFormat {
  legacy(0x00),
  p2sh(0x01),
  bech32(0x02),
  cashaddr(0x03);

  const AddressFormat(this.byteData);

  final int byteData;
}
