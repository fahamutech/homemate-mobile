/// The photo order after moving the one at [from] to [to]; the first is the cover.
List<String> movePhoto(List<String> ids, int from, int to) {
  if (from < 0 || from >= ids.length || to < 0 || to >= ids.length || from == to) return List.of(ids);
  final order = List.of(ids);
  final moved = order.removeAt(from);
  order.insert(to, moved);
  return order;
}
