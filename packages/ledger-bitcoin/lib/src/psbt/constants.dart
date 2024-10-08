import 'dart:typed_data';

enum PSBTGlobal {
  txVersion(0x02),  // Exclude for v0
  fallbackLocktime(0x03), // Exclude for v0
  inputCount(0x04), // Exclude for v0
  outputCount(0x05), // Exclude for v0
  txModifiable(0x06), // Exclude for v0
  version(0xfb);

  const PSBTGlobal(this.value);

  final int value;
}

enum PSBTIn {
  nonWitnessUTXO(0x00),
  witnessUTXO(0x01),
  partialSig(0x02),
  sighashType(0x03),
  redeemScript(0x04),
  bip32Derivation(0x06),
  finalScriptsig(0x07),
  finalScriptwitness(0x08),
  previousTXID(0x0e), // Exclude for v0
  outputIndex(0x0f), // Exclude for v0
  sequence(0x10), // Exclude for v0
  tapKeySig(0x13),
  tapBip32Derivation(0x16);

  const PSBTIn(this.value);

  final int value;
}

enum PSBTOut {
  redeemScript(0x00),
  bip32Derivation(0x02),
  amount(0x03), // Exclude for v0
  script(0x04), // Exclude for v0
  tapBip32Derivation(0x07);

  const PSBTOut(this.value);

  final int value;
}

final psbtMagicBytes = Uint8List.fromList([0x70, 0x73, 0x62, 0x74, 0xff]);

const MAX_SCRIPT_BLOCK = 50;
const DEFAULT_VERSION = 1;
const DEFAULT_LOCKTIME = 0;
const DEFAULT_SEQUENCE = 0xffffffff;
const SIGHASH_ALL = 1;
const OP_DUP = 0x76;
const OP_HASH160 = 0xa9;
const HASH_SIZE = 0x14;
const OP_EQUAL = 0x87;
const OP_EQUALVERIFY = 0x88;
const OP_CHECKSIG = 0xac;
const OP_RETURN = 0x6a;
