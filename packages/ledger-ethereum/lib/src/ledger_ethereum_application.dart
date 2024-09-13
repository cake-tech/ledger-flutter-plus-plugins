import 'dart:typed_data';

import 'package:ledger_ethereum/src/ethereum_app_config.dart';
import 'package:ledger_ethereum/src/etherum_transformer.dart';
import 'package:ledger_ethereum/src/operations/ethereum_app_config_operation.dart';
import 'package:ledger_ethereum/src/operations/ethereum_sign_msg_operation.dart';
import 'package:ledger_ethereum/src/operations/ethereum_sign_tx_operation.dart';
import 'package:ledger_ethereum/src/operations/etherum_provide_erc20_token_information_operation.dart';
import 'package:ledger_ethereum/src/operations/etherum_provide_nft_information_operation.dart';
import 'package:ledger_ethereum/src/operations/etherum_wallet_address_operation.dart';
import 'package:ledger_ethereum/src/utils/contract_address_helper.dart';
import 'package:ledger_ethereum/src/utils/erc20_info_helper.dart';
import 'package:ledger_ethereum/src/utils/nft_info_helper.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';

class EthereumLedgerApp {
  final EthereumTransformer transformer;
  final LedgerConnection connection;

  /// The [derivationPath] is a Bip32-path used to derive the public key/Address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  EthereumLedgerApp(
    this.connection, {
    this.transformer = const EthereumTransformer(),
    this.derivationPath = "m/44'/60'/0'/0/0",
  });

  Future<List<String>> getAccounts({String? accountsDerivationPath}) async {
    final (_, address, _) =
        await connection.sendOperation<(String, String, String?)>(
      EthereumWalletAddressOperation(
          derivationPath: accountsDerivationPath ?? derivationPath),
      transformer: transformer,
    );
    return [address];
  }

  Future<EthereumAppConfig> getVersion() => getAppConfig();

  Future<EthereumAppConfig> getAppConfig() =>
      connection.sendOperation<EthereumAppConfig>(
        EthereumAppConfigOperation(),
        transformer: transformer,
      );

  /// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1559.md
  ///
  /// This command signs an Ethereum transaction after having the user validate the following parameters
  ///
  /// Gas price
  /// Gas limit
  /// Recipient address
  /// Value
  ///
  /// The input data is the RLP encoded transaction, without v/r/s present.
  Future<Uint8List> signTransaction(Uint8List transaction) =>
      connection.sendOperation<Uint8List>(
        EthereumSignTxOperation(transaction, derivationPath: derivationPath),
        transformer: transformer,
      );

  /// This command signs an Ethereum message following the personal_sign specification (ethereum/go-ethereum#2940) after
  /// having the user validate the SHA-256 hash of the message being signed.
  ///
  /// This command has been supported since firmware version 1.0.8
  ///
  /// v = sig[0].toInt()
  /// r = sig.sublist(1, 1 + 32).toHexString();
  /// s = sig.sublist(1 + 32, 1 + 32 + 32).toHexString();
  Future<Uint8List> signMessage(Uint8List message) =>
      connection.sendOperation<Uint8List>(
        EthereumSignMsgOperation(message, derivationPath: derivationPath),
        transformer: transformer,
      );

  /// This command provides a trusted description of an ERC 20 token to associate a contract address with a ticker and
  /// number of decimals.
  ///
  /// It shall be run immediately before performing a transaction involving a contract calling this contract address to
  /// display the proper token information to the user if necessary, as marked in [getAppConfig] flags.
  ///
  /// The signature is computed on
  /// ticker || address || number of decimals (uint4be) || chainId (uint4be)
  ///
  /// signed by the following secp256k1 public key
  /// 0482bbf2f34f367b2e5bc21847b6566f21f0976b22d3388a9a5e446ac62d25cf725b62a2555b2dd464a4da0ab2f4d506820543af1d242470b1b1a969a27578f353
  Future<void> provideERC20TokenInformation({
    required String erc20Ticker,
    required String erc20ContractAddress,
    required int decimals,
    required int chainId,
    required String tokenInformationSignature,
  }) =>
      connection.sendOperation<void>(
        EthereumProvideERC20TokenInformationOperation(
          erc20Ticker: erc20Ticker,
          erc20ContractAddress:
              asShortenedContractAddress(erc20ContractAddress),
          decimals: decimals,
          chainId: chainId,
          tokenInformationSignature: tokenInformationSignature,
        ),
        transformer: transformer,
      );

  /// Requests the required additional information from Ledger's CDN.
  /// Only [chainId] and [erc20ContractAddress] are needed this way to provide the Ledger Device with valid ERC20-Token information
  Future<void> getAndProvideERC20TokenInformation({
    required String erc20ContractAddress,
    required int chainId,
  }) async {
    final (erc20Ticker, decimals, tokenInformationSignature) =
        await getERC20Signatures(chainId, erc20ContractAddress);

    return provideERC20TokenInformation(
      erc20Ticker: erc20Ticker,
      erc20ContractAddress: erc20ContractAddress,
      decimals: decimals,
      chainId: chainId,
      tokenInformationSignature: tokenInformationSignature,
    );
  }

  ///This command provides a trusted description of an NFT to associate a contract address with a collectionName.
  ///
  /// It shall be run immediately before performing a transaction involving a contract calling this contract address to
  /// display the proper nft information to the user if necessary, as marked in GET APP CONFIGURATION flags.
  ///
  /// The signature is computed on:
  /// type || version || len(collectionName) || collectionName || address || chainId || keyId || algorithmId
  Future<void> provideNFTInformation({
    required int type,
    required int version,
    required String collectionName,
    required String collectionAddress,
    required int chainId,
    required int keyId,
    required int algorithmId,
    required String collectionInformationSignature,
  }) =>
      connection.sendOperation<void>(
        EthereumProvideNFTInformationOperation(
          type: type,
          version: version,
          collectionName: collectionName,
          collectionAddress: collectionAddress,
          chainId: chainId,
          keyId: keyId,
          algorithmId: algorithmId,
          collectionInformationSignature: collectionInformationSignature,
        ),
        transformer: transformer,
      );

  /// Requests the required additional information from Ledger's API.
  /// Only [chainId] and [collectionAddress] are needed this way to provide the Ledger Device with valid NFT information
  Future<void> getAndProvideNFTInformation(
    LedgerDevice device, {
    required String collectionAddress,
    required int chainId,
  }) async {
    final (
      type,
      version,
      collectionName,
      keyId,
      algorithmId,
      collectionInformationSignature,
    ) = await getNFTInfo(chainId, collectionAddress);

    return provideNFTInformation(
      type: type,
      version: version,
      collectionName: collectionName,
      collectionAddress: collectionAddress,
      chainId: chainId,
      keyId: keyId,
      algorithmId: algorithmId,
      collectionInformationSignature: collectionInformationSignature,
    );
  }
}
