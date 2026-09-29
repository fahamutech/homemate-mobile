import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/wizard/photo_order.dart';

void main() {
  test('moving a photo keeps every other in its order', () {
    expect(movePhoto(['a', 'b', 'c'], 2, 0), ['c', 'a', 'b']);
    expect(movePhoto(['a', 'b', 'c'], 0, 1), ['b', 'a', 'c']);
    expect(movePhoto(['a', 'b', 'c'], 1, 2), ['a', 'c', 'b']);
  });

  test('a move out of range, or to the same place, changes nothing', () {
    expect(movePhoto(['a', 'b'], 0, 0), ['a', 'b']);
    expect(movePhoto(['a', 'b'], 0, 5), ['a', 'b']);
    expect(movePhoto(const [], 0, 0), isEmpty);
  });
}
