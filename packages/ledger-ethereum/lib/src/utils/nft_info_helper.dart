import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;

const nftExplorerBaseURL = "https://nft.api.live.ledger.com/v1/ethereum";

Future<(int, int, String, int, int, String)> getNFTInfo(int chainId, String contractAddress) async {
  final url = '$nftExplorerBaseURL/$chainId/contracts/$contractAddress';

  final response = await http.get(Uri.parse(url));

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final payload = hex.decode(body['payload'] as String);

  
  final type = payload[0];
  final version = payload[1];
  final collectionLength = payload[2];

  final collectionName = ascii.decode(payload.sublist(3, 3 + collectionLength));

  final keyId = payload[3 + collectionLength + 20 + 8];
  final algorithmId = payload[3 + collectionLength + 20 + 8 + 1];
  final signature = hex.encode(payload.sublist(3 + collectionLength + 20 + 8 + 3));

  return (type, version, collectionName, keyId, algorithmId, signature);
}
