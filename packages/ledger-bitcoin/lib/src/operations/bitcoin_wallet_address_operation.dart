import 'dart:typed_data';

import 'package:ledger_bitcoin/src/ledger/ledger_input_operation.dart';
import 'package:ledger_bitcoin/src/wallet_policy.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class BitcoinWalletAddressOperation extends LedgerInputOperation<Uint8List> {
  /// If [displayWalletAddress] is set to true the Wallet Address will be shown to the user on the ledger device
  final bool displayWalletAddress;

  final WalletPolicy walletPolicy;
  final Uint8List? walletHMAC;
  final int change;
  final int addressIndex;

  BitcoinWalletAddressOperation({
    required this.walletPolicy,
    required this.displayWalletAddress,
    required this.change,
    required this.addressIndex,
    this.walletHMAC,
  }) : super(0xE1, 0x03);

  @override
  Future<Uint8List> read(ByteDataReader reader) async =>
      reader.read(reader.remainingLength);

  @override
  int get p1 => 0x00;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> writeInputData() async {
    final walletHMACBytes = walletHMAC ?? Uint8List(32);

    // 0x01 - Show the wallet address on the device
    // 0x00 - Don't show the wallet address on the device
    final displayWalletAddressByte = displayWalletAddress ? 0x01 : 0x00;

    final writer = ByteDataWriter()
      ..writeUint8(displayWalletAddressByte)
      ..write(walletPolicy.id)
      ..write(walletHMACBytes)
      ..writeUint8(change)
      ..writeUint32(addressIndex);

    return writer.toBytes();
  }
}
