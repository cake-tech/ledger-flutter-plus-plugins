import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ledger_ethereum/src/ledger/ethereum_instructions.dart';
import 'package:ledger_ethereum/src/ledger/ledger_input_operation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

/// This command provides a trusted description of an ERC 20 token to associate a contract address with a ticker and
/// number of decimals.
///
/// It shall be run immediately before performing a transaction involving a contract calling this contract address to
/// display the proper token information to the user if necessary, as marked in GET APP CONFIGURATION flags.
///
/// The signature is computed on
/// ticker || address || number of decimals (uint4be) || chainId (uint4be)
///
/// signed by the following secp256k1 public key
/// 0482bbf2f34f367b2e5bc21847b6566f21f0976b22d3388a9a5e446ac62d25cf725b62a2555b2dd464a4da0ab2f4d506820543af1d242470b1b1a969a27578f353
class EthereumProvideERC20TokenInformationOperation
    extends LedgerInputOperation<void> {
  final String erc20Ticker;
  final String erc20ContractAddress;
  final int decimals;
  final int chainId;
  final String tokenInformationSignature;

  EthereumProvideERC20TokenInformationOperation({
    required this.erc20Ticker,
    required this.erc20ContractAddress,
    required this.decimals,
    required this.chainId,
    required this.tokenInformationSignature,
  }) : super(ethCLA, provideERC20TokenInformationINS);

  @override
  Future<void> read(ByteDataReader reader) async {}

  @override
  int get p1 => 0x00;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> writeInputData() async {
    final dataWriter = ByteDataWriter()
      ..writeUint8(erc20Ticker.length)
      ..write(ascii.encode(erc20Ticker))
      ..write(hex.decode(erc20ContractAddress))
      ..writeUint32(decimals)
      ..writeUint32(chainId)
      ..write(hex.decode(tokenInformationSignature));

    return dataWriter.toBytes();
  }
}
