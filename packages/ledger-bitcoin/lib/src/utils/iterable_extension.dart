
extension IsSorted on Iterable {
  bool isSorted<T>([int Function(T, T)? compare]) {
    if (length < 2) return true;
    compare ??= (T a, T b) => (a as Comparable<T>).compareTo(b);
    T prev = first;
    for (var i = 1; i < length; i++) {
      T next = elementAt(i);
      if (compare(prev, next) > 0) return false;
      prev = next;
    }
    return true;
  }
}
