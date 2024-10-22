/*
 * Bitcoin BIP32 path helpers
 * (C) 2016 Alex Beregszaszi
 * (C) 2023 CakeWallet Devs
 */

class BIPPath {
  static const int hardened = 0x80000000;
  final List<int> _path;

  BIPPath.fromPathArray(this._path) {
    if (_path.isEmpty) {
      throw Exception('Path must contain at least one level');
    }
  }

  factory BIPPath.fromString(String text, {bool requireRoot = false}) {
    // skip the root
    if (text.startsWith("m/")) {
      text = text.substring(2);
    } else if (requireRoot) {
      throw Exception('Root element is required');
    }

    var path = text.split('/');
    var ret = <int>[];
    for (var i = 0; i < path.length; i++) {
      final tmp = RegExp(r"(\d+)([hH']?)").firstMatch(path[i])!;
      ret.add(int.parse(tmp.group(1)!, radix: 10));
      if (ret[i] >= hardened) {
        throw Exception('Invalid child index');
      }

      if (['h', 'H', '\''].contains(tmp.group(2)!)) {
        ret[i] += hardened;
      } else if (tmp.groupCount > 2) {
        throw Exception('Invalid modifier');
      }
    }
    return BIPPath.fromPathArray(ret);
  }

  List<int> toPathArray() => _path;

  @override
  String toString({bool noRoot = false, bool oldStyle = false}) {
    final ret = <String>[];
    for (final value in _path) {
      if (value & hardened > 0) {
        ret.add('${value & ~hardened}${oldStyle ? 'h' : '\''}');
      } else {
        ret.add('$value');
      }
    }
    return (noRoot ? '' : 'm/') + ret.join('/');
  }
}
