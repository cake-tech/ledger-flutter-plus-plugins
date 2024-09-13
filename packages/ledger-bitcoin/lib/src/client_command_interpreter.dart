import 'dart:core';
import 'dart:typed_data';

import 'package:ledger_bitcoin/src/commands/client_command.dart';
import 'package:ledger_bitcoin/src/commands/get_merkle_leaf_index_command.dart';
import 'package:ledger_bitcoin/src/commands/get_merkle_leaf_proof_command.dart';
import 'package:ledger_bitcoin/src/commands/get_more_elements_command.dart';
import 'package:ledger_bitcoin/src/commands/get_preimage_command.dart';
import 'package:ledger_bitcoin/src/utils/merkle/merkle.dart';
import 'package:ledger_bitcoin/src/utils/merkle/merkle_map.dart';
import 'package:ledger_bitcoin/src/utils/uint8list_extension.dart';
import 'package:ledger_bitcoin/src/utils/utils.dart';

import 'commands/yield_command.dart';

class ClientCommandInterpreter {
  final Map<String, Merkle> _roots = {};
  final Map<String, Uint8List> _preimages = {};
  final Map<ClientCommandCode, ClientCommand> _commands = {};
  final List<Uint8List> _yielded = [];
  final List<Uint8List> _queue = [];

  ClientCommandInterpreter(void Function() progressCallback) {
    final commands = [
      YieldCommand(_yielded, progressCallback),
      GetPreimageCommand(_preimages, _queue),
      GetMerkleLeafIndexCommand(_roots),
      GetMerkleLeafProofCommand(_roots, _queue),
      GetMoreElementsCommand(_queue),
    ];

    for (final cmd in commands) {
      if (_commands.keys.contains(cmd.code)) {
        throw Exception('Multiple commands with code ${cmd.code}');
      }
      _commands[cmd.code] = cmd;
    }
  }

  List<Uint8List> get yielded => _yielded;

  Map<String, Uint8List> get preimages => _preimages;

  void addKnownPreimage(Uint8List preimage) {
    _preimages[sha256Hasher(preimage).toHexString()] = preimage;
  }

  void addKnownList(Iterable<Uint8List> elements) {
    for (final el in elements) {
      final bytesBuilder = BytesBuilder()
        ..add([0])
        ..add(el);
      addKnownPreimage(bytesBuilder.toBytes());
    }

    final mt = Merkle(elements.map((el) => hashLeaf(el)).toList());
    _roots[mt.root.toHexString()] = mt;
  }

  void addKnownMapping(MerkleMap mm) {
    addKnownList(mm.keys);
    addKnownList(mm.values);
  }

  Uint8List execute(Uint8List request) {
    if (request.isEmpty) throw Exception("Unexpected empty command");

    final cmdCode = ClientCommandCode.fromInt(request[0]);
    final cmd = _commands[cmdCode];
    if (cmd == null) throw Exception('Unexpected command code $cmdCode');

    return cmd.execute(request);
  }
}
