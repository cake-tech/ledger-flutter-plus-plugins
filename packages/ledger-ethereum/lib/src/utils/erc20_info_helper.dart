import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;
import 'package:ledger_ethereum/src/ledger_ethereum_exception.dart';
import 'package:ledger_ethereum/src/utils/contract_address_helper.dart';
import 'package:ledger_ethereum/src/utils/int_uint8list_extension.dart';
import 'package:ledger_ethereum/src/utils/string_uint8list_extension.dart';

const cryptoassetsBaseURL = "https://cdn.live.ledger.com/cryptoassets";

Future<(String, int, String)> getERC20Signatures(
    int chainId, String contractAddress) async {
  final url = '$cryptoassetsBaseURL/evm/$chainId/erc20-signatures.json';

  final response = await http.get(Uri.parse(url));

  final body = jsonDecode(response.body) as String;
  final result = _parse(body);
  final sigKey = "$chainId:${contractAddress.toLowerCase()}";

  if (!result.containsKey(sigKey)) {
    throw LedgerEthereumException(
        message:
            "$contractAddress on $chainId seems to be not trusted by ledger");
  }

  final tokenData = result[sigKey]!;
  return (tokenData.ticker, tokenData.decimals, tokenData.signature);
}

Map<String, _TokenInfo> _parse(String erc20SignaturesBlob) {
  final buf = base64.decode(erc20SignaturesBlob);

  final map = <String, _TokenInfo>{};
  var i = 0;

  while (i < buf.length) {
    final length = buf.sublist(i, i + 4).toInt();
    i += 4;
    final item = buf.sublist(i, i + length);
    var j = 0;
    final tickerLength = item[j];
    j += 1;
    final ticker = item.sublist(j, j + tickerLength).toAsciiString();
    j += tickerLength;
    final contractAddress =
        asContractAddress(item.sublist(j, j + 20).toHexString());
    j += 20;
    final decimals = item.sublist(j, j + 4).toInt();
    j += 4;
    final chainId = item.sublist(j, j + 4).toInt();
    j += 4;
    final signature = hex.encode(item.sublist(j));

    map["$chainId:$contractAddress"] = _TokenInfo(
      ticker: ticker,
      contractAddress: contractAddress,
      decimals: decimals,
      chainId: chainId,
      signature: signature,
      data: item,
    );
    i += length;
  }

  return map;
}

class _TokenInfo {
  final String ticker;
  final String contractAddress;
  final int decimals;
  final int chainId;
  final String signature;
  final Uint8List data;

  _TokenInfo({
    required this.ticker,
    required this.contractAddress,
    required this.decimals,
    required this.chainId,
    required this.signature,
    required this.data,
  });
}
