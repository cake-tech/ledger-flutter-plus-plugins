String asContractAddress(String addr) {
  final a = addr.toLowerCase();
  return a.startsWith("0x") ? a : "0x$a";
}

String asShortenedContractAddress(String addr) => addr.replaceAll("0x", "");
