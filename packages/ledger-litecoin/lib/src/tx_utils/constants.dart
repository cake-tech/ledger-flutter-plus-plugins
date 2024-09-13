// the maximum number of bytes allowed in a single chunk when processing bitcoin script data.
// if the Bitcoin script is too large, we will process it in several chunks.
const MAX_SCRIPT_BLOCK = 50;
const DEFAULT_VERSION = 1;
const DEFAULT_LOCKTIME = 0;
// input sequence for non-rbf transactions
const DEFAULT_SEQUENCE = 0xffffffff;
// SIGHASH flags(Sign all inputs and outputs)
// refer to https://wiki.bitcoinsv.io/index.php/SIGHASH_flags for more details
const SIGHASH_ALL = 1;
// refer to https://en.bitcoin.it/wiki/Script for Opcodes(OP_DUP, OP_HASH160...) that are used in bitcoin script
const OP_DUP = 0x76;
const OP_HASH160 = 0xa9;
const HASH_SIZE = 0x14;
const OP_EQUAL = 0x87;
const OP_EQUALVERIFY = 0x88;
const OP_CHECKSIG = 0xac;
const OP_RETURN = 0x6a;
