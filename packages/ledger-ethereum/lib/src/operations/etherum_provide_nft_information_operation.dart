import 'dart:convert';
import 'dart:typed_data';

import 'package:ledger_ethereum/src/ledger/ethereum_instructions.dart';
import 'package:ledger_ethereum/src/ledger/ledger_input_operation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

///This command provides a trusted description of an NFT to associate a contract address with a collectionName.
///
/// It shall be run immediately before performing a transaction involving a contract calling this contract address to
/// display the proper nft information to the user if necessary, as marked in GET APP CONFIGURATION flags.
///
/// The signature is computed on:
/// type || version || len(collectionName) || collectionName || address || chainId || keyId || algorithmId
class EthereumProvideNFTInformationOperation
    extends LedgerInputOperation<void> {
  final int type;
  final int version;
  final String collectionName;
  final String collectionAddress;
  final int chainId;
  final int keyId;
  final int algorithmId;
  final String collectionInformationSignature;

  EthereumProvideNFTInformationOperation({
    this.type = 0x01,
    this.version = 0x01,
    required this.collectionName,
    required this.collectionAddress,
    required this.chainId,
    this.keyId = 0x01,
    this.algorithmId = 0x01,
    required this.collectionInformationSignature,
  }) : super(ethCLA, provideNFTInformationINS);

  @override
  Future<void> read(ByteDataReader reader) async {}

  @override
  int get p1 => 0x00;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> writeInputData() async {
    final dataWriter = ByteDataWriter()
      ..writeUint8(type)
      ..writeUint8(version)
      ..writeUint8(collectionName.length)
      ..write(ascii.encode(collectionName))
      ..write(hex.decode(collectionAddress))
      ..writeUint64(chainId)
      ..writeUint8(keyId)
      ..writeUint8(algorithmId)
      ..writeUint8(collectionInformationSignature.length)
      ..write(hex.decode(collectionInformationSignature));

    return dataWriter.toBytes();
  }
}
