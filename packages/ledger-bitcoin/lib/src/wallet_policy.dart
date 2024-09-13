import 'dart:convert';
import 'dart:typed_data';

import 'package:ledger_bitcoin/src/utils/buffer_writer.dart';
import 'package:ledger_bitcoin/src/utils/merkle/merkle.dart';
import 'package:ledger_bitcoin/src/utils/utils.dart';

class WalletPolicy {
  final String name;
  final String descriptorTemplate;
  final List<String> keys;

  /// Creates and instance of a wallet policy.
  /// [name] an ascii string, up to 16 bytes long; it must be an empty string for default wallet policies
  /// [descriptorTemplate] the wallet policy template
  /// [keys] and array of the keys, with the key derivation information
  WalletPolicy(this.name, this.descriptorTemplate, this.keys);

  /// Returns the unique 32-bytes id of this wallet policy.
  Uint8List get id => sha256Hasher(serialize());

  /// Serializes the wallet policy for transmission via the hardware wallet protocol.
  Uint8List serialize() {
    final keyBuffers = keys.map((k) => ascii.encode(k));
    final merkle = Merkle(keyBuffers.map((k) => hashLeaf(k)).toList());

    final buf = BufferWriter()
      ..writeUInt8(0x01) // wallet type (policy map)
      ..writeUInt8(0) // length of wallet name (empty string for default wallets)
      ..writeVarSlice(ascii.encode(descriptorTemplate))
      ..writeVarInt(keys.length)
      ..writeSlice(merkle.root);
    return buf.buffer();
  }
}

/// Legacy addresses as per BIP-44
class LegacyWalletPolicy extends WalletPolicy {
  LegacyWalletPolicy(List<String> keys) : super("", "pkh(@0)", keys);
}

/// Native segwit addresses per BIP-84
class NativeSegwitWalletPolicy extends WalletPolicy {
  NativeSegwitWalletPolicy(List<String> keys) : super("", "wpkh(@0)", keys);
}

/// Nested segwit addresses as per BIP-49
class NestedSegwitWalletPolicy extends WalletPolicy {
  NestedSegwitWalletPolicy(List<String> keys) : super("", "sh(wpkh(@0))", keys);
}

/// Single Key P2TR as per BIP-86
class TaprootWalletPolicy extends WalletPolicy {
  TaprootWalletPolicy(List<String> keys) : super("", "tr(@0)", keys);
}
