import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/widgets/commons/icon_registry.dart';

void main() {
  test('107 unique keys in 13 groups (71 base + 36 extra)', () {
    final keys = IconRegistry.all.map((e) => e.key).toSet();
    expect(IconRegistry.all.length, 107);
    expect(keys.length, 107);
    expect(IconRegistry.groups.length, 13);
    expect(IconRegistry.all.where((e) => e.isExtra).length, 36);
    for (final g in IconRegistry.groups) {
      expect(IconRegistry.inGroup(g.id), isNotEmpty, reason: g.id);
    }
  });

  test('every legacy seed icon maps to a real icon', () {
    const legacy = [
      'assets/makanan/bowl.png',
      'assets/makanan/soft-drink.png',
      'assets/belanja/shopping-bag.png',
      'assets/transportasi/car.png',
      'assets/kesehatan/health-care.png',
      'assets/hiburan/cinema.png',
      'assets/pendidikan/education.png',
      'assets/olahraga/sport.png',
      'assets/berpergian/travel.png',
      'assets/pribadi/briefcase.png',
      'assets/pribadi/wifi.png',
      'assets/keuangan/uang.png',
      'assets/keuangan/coin.png',
      'assets/keuangan/stock.png',
      'assets/pribadi/meeting.png',
      'assets/keuangan/nabung.png',
      'assets/keuangan/bank.png',
      'assets/keuangan/dompet.png',
    ];
    for (final path in legacy) {
      final key = IconRegistry.legacyToKey(iconPath: path);
      expect(IconRegistry.contains(key), isTrue, reason: path);
      expect(key, isNot(IconRegistry.fallbackKey), reason: path);
    }
    expect(IconRegistry.legacyToKey(), IconRegistry.fallbackKey);
  });

  test('search matches Indonesian labels', () {
    expect(IconRegistry.search('kopi').map((e) => e.key), contains('kopi'));
  });
}
