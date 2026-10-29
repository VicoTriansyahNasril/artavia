import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One selectable category/account icon (Lucide line icon, ISC licence).
class IconEntry {
  /// Stable key stored in the DB (`icon_key`).
  final String key;
  final IconData icon;

  /// Indonesian label shown under the icon and used for search.
  final String label;
  final String group;

  /// True for the 36 "ikon tambahan" (board 01, bottom half).
  final bool isExtra;

  const IconEntry(this.key, this.icon, this.label, this.group,
      {this.isExtra = false});
}

/// An icon group as shown on the board, with its default palette index.
class IconGroup {
  final String id;
  final String label;
  final int paletteIndex;
  const IconGroup(this.id, this.label, this.paletteIndex);
}

/// The 107 Kobalt category icons in 13 groups (71 base + 36 extra).
class IconRegistry {
  IconRegistry._();

  static const String fallbackKey = 'lainnya';

  static const List<IconGroup> groups = [
    IconGroup('makanan', 'Makanan & minuman', 1),
    IconGroup('transportasi', 'Transportasi', 6),
    IconGroup('rumah', 'Rumah & tagihan', 5),
    IconGroup('belanja', 'Belanja & gaya hidup', 9),
    IconGroup('kesehatan', 'Kesehatan & olahraga', 10),
    IconGroup('hiburan', 'Hiburan & liburan', 8),
    IconGroup('pendidikan', 'Pendidikan & kerja', 7),
    IconGroup('keluarga', 'Keluarga & sosial', 0),
    IconGroup('keuangan', 'Keuangan & kewajiban', 11),
    IconGroup('pemasukan', 'Pemasukan', 4),
    IconGroup('lainnya', 'Lainnya', 2),
    IconGroup('usaha', 'Usaha', 3),
    IconGroup('digital', 'Digital', 6),
  ];

  static const List<IconEntry> all = [
    // Makanan & minuman
    IconEntry('makan', LucideIcons.utensils, 'Makan', 'makanan'),
    IconEntry('kopi', LucideIcons.coffee, 'Kopi', 'makanan'),
    IconEntry('minuman', LucideIcons.cupSoda, 'Minuman', 'makanan'),
    IconEntry('camilan', LucideIcons.pizza, 'Camilan', 'makanan'),
    IconEntry('kue', LucideIcons.cakeSlice, 'Kue', 'makanan'),
    IconEntry('buah', LucideIcons.apple, 'Buah', 'makanan'),
    IconEntry('warung', LucideIcons.soup, 'Warung', 'makanan'),
    IconEntry('dapur', LucideIcons.shoppingCart, 'Dapur', 'makanan'),
    IconEntry('es_krim', LucideIcons.iceCreamCone, 'Es krim', 'makanan',
        isExtra: true),
    IconEntry('susu', LucideIcons.milk, 'Susu', 'makanan', isExtra: true),
    IconEntry('sarapan', LucideIcons.egg, 'Sarapan', 'makanan', isExtra: true),
    IconEntry('kue_kering', LucideIcons.cookie, 'Kue kering', 'makanan',
        isExtra: true),
    IconEntry('masak', LucideIcons.chefHat, 'Masak', 'makanan', isExtra: true),
    // Transportasi
    IconEntry('mobil', LucideIcons.car, 'Mobil', 'transportasi'),
    IconEntry('bus', LucideIcons.bus, 'Bus', 'transportasi'),
    IconEntry('kereta', LucideIcons.trainFront, 'Kereta', 'transportasi'),
    IconEntry('pesawat', LucideIcons.plane, 'Pesawat', 'transportasi'),
    IconEntry('sepeda', LucideIcons.bike, 'Sepeda', 'transportasi'),
    IconEntry('bensin', LucideIcons.fuel, 'Bensin', 'transportasi'),
    IconEntry('parkir', LucideIcons.squareParking, 'Parkir', 'transportasi'),
    IconEntry('kapal', LucideIcons.ship, 'Kapal', 'transportasi',
        isExtra: true),
    IconEntry('ojek', LucideIcons.navigation, 'Ojek online', 'transportasi',
        isExtra: true),
    // Rumah & tagihan
    IconEntry('sewa', LucideIcons.house, 'Sewa', 'rumah'),
    IconEntry('listrik', LucideIcons.zap, 'Listrik', 'rumah'),
    IconEntry('air', LucideIcons.droplet, 'Air', 'rumah'),
    IconEntry('internet', LucideIcons.wifi, 'Internet', 'rumah'),
    IconEntry('pulsa', LucideIcons.smartphone, 'Pulsa', 'rumah'),
    IconEntry('gas', LucideIcons.flame, 'Gas', 'rumah'),
    IconEntry('perbaikan', LucideIcons.wrench, 'Perbaikan', 'rumah'),
    IconEntry('langganan', LucideIcons.tv, 'Langganan', 'rumah'),
    IconEntry('perabot', LucideIcons.sofa, 'Perabot', 'rumah', isExtra: true),
    IconEntry('kasur', LucideIcons.bedDouble, 'Kasur', 'rumah', isExtra: true),
    IconEntry('lampu', LucideIcons.lightbulb, 'Lampu', 'rumah', isExtra: true),
    IconEntry('kebersihan', LucideIcons.trash, 'Kebersihan', 'rumah',
        isExtra: true),
    IconEntry('kos', LucideIcons.keyRound, 'Kos', 'rumah', isExtra: true),
    // Belanja & gaya hidup
    IconEntry('belanja', LucideIcons.shoppingBag, 'Belanja', 'belanja'),
    IconEntry('pakaian', LucideIcons.shirt, 'Pakaian', 'belanja'),
    IconEntry('salon', LucideIcons.scissors, 'Salon', 'belanja'),
    IconEntry('perhiasan', LucideIcons.gem, 'Perhiasan', 'belanja'),
    IconEntry(
        'belanja_online', LucideIcons.package, 'Belanja online', 'belanja'),
    IconEntry('elektronik', LucideIcons.laptop, 'Elektronik', 'belanja'),
    IconEntry('gadget', LucideIcons.headphones, 'Gadget', 'belanja'),
    IconEntry('hadiah', LucideIcons.gift, 'Hadiah', 'belanja'),
    IconEntry('jam_tangan', LucideIcons.watch, 'Jam tangan', 'belanja',
        isExtra: true),
    IconEntry('kacamata', LucideIcons.glasses, 'Kacamata', 'belanja',
        isExtra: true),
    // Kesehatan & olahraga
    IconEntry('kesehatan', LucideIcons.heart, 'Kesehatan', 'kesehatan'),
    IconEntry('obat', LucideIcons.pill, 'Obat', 'kesehatan'),
    IconEntry('dokter', LucideIcons.stethoscope, 'Dokter', 'kesehatan'),
    IconEntry('gym', LucideIcons.dumbbell, 'Gym', 'kesehatan'),
    IconEntry('olahraga', LucideIcons.activity, 'Olahraga', 'kesehatan'),
    IconEntry('perawatan', LucideIcons.smile, 'Perawatan diri', 'kesehatan'),
    IconEntry('vaksin', LucideIcons.syringe, 'Vaksin', 'kesehatan',
        isExtra: true),
    IconEntry('rumah_sakit', LucideIcons.cross, 'Rumah sakit', 'kesehatan',
        isExtra: true),
    IconEntry('mata', LucideIcons.eye, 'Mata', 'kesehatan', isExtra: true),
    // Hiburan & liburan
    IconEntry('film', LucideIcons.film, 'Film', 'hiburan'),
    IconEntry('musik', LucideIcons.music, 'Musik', 'hiburan'),
    IconEntry('game', LucideIcons.gamepad2, 'Game', 'hiburan'),
    IconEntry('tiket', LucideIcons.ticket, 'Tiket', 'hiburan'),
    IconEntry('fotografi', LucideIcons.camera, 'Fotografi', 'hiburan'),
    IconEntry('liburan', LucideIcons.tent, 'Liburan', 'hiburan'),
    IconEntry('karaoke', LucideIcons.mic, 'Karaoke', 'hiburan', isExtra: true),
    IconEntry('turnamen', LucideIcons.trophy, 'Turnamen', 'hiburan',
        isExtra: true),
    IconEntry('hobi_seni', LucideIcons.palette, 'Hobi seni', 'hiburan',
        isExtra: true),
    IconEntry('mendaki', LucideIcons.mountain, 'Mendaki', 'hiburan',
        isExtra: true),
    IconEntry('pantai', LucideIcons.umbrella, 'Pantai', 'hiburan',
        isExtra: true),
    // Pendidikan & kerja
    IconEntry('buku', LucideIcons.bookOpen, 'Buku', 'pendidikan'),
    IconEntry('sekolah', LucideIcons.graduationCap, 'Sekolah', 'pendidikan'),
    IconEntry('alat_tulis', LucideIcons.pen, 'Alat tulis', 'pendidikan'),
    IconEntry('kantor', LucideIcons.briefcase, 'Kantor', 'pendidikan'),
    IconEntry('cetak', LucideIcons.printer, 'Cetak', 'pendidikan'),
    IconEntry('kursus_bahasa', LucideIcons.globe, 'Kursus bahasa', 'pendidikan',
        isExtra: true),
    IconEntry('kalkulator', LucideIcons.calculator, 'Kalkulator', 'pendidikan',
        isExtra: true),
    IconEntry('tas_sekolah', LucideIcons.backpack, 'Tas sekolah', 'pendidikan',
        isExtra: true),
    // Keluarga & sosial
    IconEntry('anak', LucideIcons.baby, 'Anak', 'keluarga'),
    IconEntry('keluarga', LucideIcons.users, 'Keluarga', 'keluarga'),
    IconEntry('hewan', LucideIcons.pawPrint, 'Hewan peliharaan', 'keluarga'),
    IconEntry('donasi', LucideIcons.handHeart, 'Donasi', 'keluarga'),
    IconEntry('ibadah', LucideIcons.moon, 'Ibadah', 'keluarga'),
    IconEntry('orang_tua', LucideIcons.user, 'Orang tua', 'keluarga',
        isExtra: true),
    IconEntry('kondangan', LucideIcons.mail, 'Kondangan', 'keluarga',
        isExtra: true),
    // Keuangan & kewajiban
    IconEntry('cicilan', LucideIcons.creditCard, 'Cicilan', 'keuangan'),
    IconEntry('biaya_bank', LucideIcons.landmark, 'Biaya bank', 'keuangan'),
    IconEntry('utang', LucideIcons.receipt, 'Utang', 'keuangan'),
    IconEntry('tabungan', LucideIcons.piggyBank, 'Tabungan', 'keuangan'),
    IconEntry('asuransi', LucideIcons.shield, 'Asuransi', 'keuangan'),
    IconEntry('pajak', LucideIcons.percent, 'Pajak', 'keuangan'),
    IconEntry('denda', LucideIcons.scale, 'Denda', 'keuangan', isExtra: true),
    // Pemasukan
    IconEntry('gaji', LucideIcons.briefcaseBusiness, 'Gaji', 'pemasukan'),
    IconEntry('bonus', LucideIcons.award, 'Bonus', 'pemasukan'),
    IconEntry('investasi', LucideIcons.trendingUp, 'Investasi', 'pemasukan'),
    IconEntry('bunga', LucideIcons.coins, 'Bunga', 'pemasukan'),
    IconEntry('usaha', LucideIcons.store, 'Usaha', 'pemasukan'),
    IconEntry('uang_tunai', LucideIcons.banknote, 'Uang tunai', 'pemasukan'),
    IconEntry(
        'pengembalian', LucideIcons.rotateCcw, 'Pengembalian', 'pemasukan'),
    // Lainnya
    IconEntry('lainnya', LucideIcons.ellipsis, 'Lainnya', 'lainnya'),
    IconEntry('label', LucideIcons.tag, 'Label', 'lainnya'),
    IconEntry('favorit', LucideIcons.star, 'Favorit', 'lainnya'),
    IconEntry('kebun', LucideIcons.sprout, 'Kebun', 'lainnya'),
    IconEntry('transfer', LucideIcons.arrowRightLeft, 'Transfer', 'lainnya'),
    // Usaha (kelompok baru)
    IconEntry('promosi', LucideIcons.megaphone, 'Promosi', 'usaha',
        isExtra: true),
    IconEntry('ongkir', LucideIcons.truck, 'Ongkir', 'usaha', isExtra: true),
    IconEntry('pesanan', LucideIcons.clipboardList, 'Pesanan', 'usaha',
        isExtra: true),
    IconEntry('faktur', LucideIcons.fileText, 'Faktur', 'usaha', isExtra: true),
    // Digital (kelompok baru)
    IconEntry('awan', LucideIcons.cloud, 'Penyimpanan awan', 'digital',
        isExtra: true),
    IconEntry('aplikasi', LucideIcons.code, 'Aplikasi', 'digital',
        isExtra: true),
    IconEntry('hosting', LucideIcons.server, 'Hosting', 'digital',
        isExtra: true),
    IconEntry('kuota', LucideIcons.signal, 'Kuota data', 'digital',
        isExtra: true),
  ];

  static final Map<String, IconEntry> _byKey = {
    for (final e in all) e.key: e,
  };

  /// Entry for a stored key; unknown/null keys fall back to "Lainnya".
  static IconEntry byKey(String? key) => _byKey[key] ?? _byKey[fallbackKey]!;

  static bool contains(String? key) => _byKey.containsKey(key);

  static List<IconEntry> inGroup(String groupId) =>
      all.where((e) => e.group == groupId).toList();

  /// Case-insensitive search on label, key and group label.
  static List<IconEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    final groupLabels = {for (final g in groups) g.id: g.label.toLowerCase()};
    return all
        .where((e) =>
            e.label.toLowerCase().contains(q) ||
            e.key.contains(q) ||
            groupLabels[e.group]!.contains(q))
        .toList();
  }

  /// Account icons in the account form, by account type label.
  static String accountTypeKey(String type) =>
      _accountTypeKeys[type] ?? 'uang_tunai';

  static const Map<String, String> _accountTypeKeys = {
    'Kas Tunai': 'uang_tunai',
    'Bank': 'biaya_bank',
    'Kartu Kredit': 'cicilan',
    'Dompet Digital': 'pulsa',
    'Tabungan': 'tabungan',
    'Investasi': 'investasi',
    'Pinjaman': 'utang',
    'Investasi Aset': 'sewa',
    'Lainnya': 'lainnya',
  };

  // Ordered: first matching keyword wins.
  static const List<MapEntry<String, String>> _legacyKeywords = [
    MapEntry('latte', 'kopi'),
    MapEntry('coffee', 'kopi'),
    MapEntry('coconut', 'minuman'),
    MapEntry('soft-drink', 'minuman'),
    MapEntry('energy-drink', 'minuman'),
    MapEntry('juice', 'minuman'),
    MapEntry('fruit', 'buah'),
    MapEntry('salad', 'buah'),
    MapEntry('laddu', 'kue'),
    MapEntry('burger', 'camilan'),
    MapEntry('fast-food', 'camilan'),
    MapEntry('take-away', 'warung'),
    MapEntry('packet', 'warung'),
    MapEntry('ingredient', 'dapur'),
    MapEntry('chilli', 'dapur'),
    MapEntry('bowl', 'makan'),
    MapEntry('dinner', 'makan'),
    MapEntry('gas-station', 'bensin'),
    MapEntry('parking', 'parkir'),
    MapEntry('train', 'kereta'),
    MapEntry('maritime', 'kapal'),
    MapEntry('sportbike', 'sepeda'),
    MapEntry('tyre', 'perbaikan'),
    MapEntry('engine', 'perbaikan'),
    MapEntry('traveling_car', 'mobil'),
    MapEntry('car', 'mobil'),
    MapEntry('sun-umbrella', 'pantai'),
    MapEntry('skiing', 'mendaki'),
    MapEntry('meadow', 'mendaki'),
    MapEntry('gift', 'hadiah'),
    MapEntry('voucher', 'label'),
    MapEntry('discount', 'label'),
    MapEntry('tag', 'label'),
    MapEntry('online-shop', 'belanja_online'),
    MapEntry('ecommerce', 'belanja_online'),
    MapEntry('shopping-cart', 'dapur'),
    MapEntry('cart', 'dapur'),
    MapEntry('store', 'usaha'),
    MapEntry('stock', 'investasi'),
    MapEntry('fashion', 'pakaian'),
    MapEntry('shopping', 'belanja'),
    MapEntry('cinema', 'film'),
    MapEntry('play-button', 'film'),
    MapEntry('media', 'film'),
    MapEntry('game', 'game'),
    MapEntry('poker', 'game'),
    MapEntry('puzzle', 'game'),
    MapEntry('headphone', 'gadget'),
    MapEntry('music', 'musik'),
    MapEntry('vip-pass', 'tiket'),
    MapEntry('dumbbell', 'gym'),
    MapEntry('weightlifting', 'gym'),
    MapEntry('first-aid', 'obat'),
    MapEntry('dental', 'dokter'),
    MapEntry('provider', 'dokter'),
    MapEntry('patient', 'dokter'),
    MapEntry('hospital', 'rumah_sakit'),
    MapEntry('heart', 'kesehatan'),
    MapEntry('health', 'kesehatan'),
    MapEntry('gastro', 'kesehatan'),
    MapEntry('battery', 'listrik'),
    MapEntry('retirement', 'tabungan'),
    MapEntry('balance', 'denda'),
    MapEntry('time', 'jam_tangan'),
    MapEntry('campus', 'sekolah'),
    MapEntry('working-at-home', 'sewa'),
    MapEntry('portfolio', 'kantor'),
    MapEntry('briefcase', 'kantor'),
    MapEntry('office', 'kantor'),
    MapEntry('meeting', 'kantor'),
    MapEntry('working', 'kantor'),
    MapEntry('wifi', 'internet'),
    MapEntry('connection', 'internet'),
    MapEntry('portal', 'internet'),
    MapEntry('folder', 'faktur'),
    MapEntry('setting', 'perbaikan'),
    MapEntry('presentation', 'buku'),
    MapEntry('idea', 'lampu'),
    MapEntry('financial-education', 'tabungan'),
    MapEntry('online', 'buku'),
    MapEntry('education', 'sekolah'),
    MapEntry('learning', 'buku'),
    MapEntry('bank', 'biaya_bank'),
    MapEntry('borrow', 'utang'),
    MapEntry('kredit', 'cicilan'),
    MapEntry('nabung', 'tabungan'),
    MapEntry('dompet', 'uang_tunai'),
    MapEntry('uang', 'uang_tunai'),
    MapEntry('coin', 'bunga'),
  ];

  static const Map<String, String> _legacyFolders = {
    'makanan': 'makan',
    'transportasi': 'mobil',
    'berpergian': 'liburan',
    'belanja': 'belanja',
    'hiburan': 'film',
    'kesehatan': 'kesehatan',
    'olahraga': 'olahraga',
    'pendidikan': 'sekolah',
    'pribadi': 'kantor',
    'kehidupan': 'kesehatan',
    'keuangan': 'tabungan',
  };

  /// Maps a pre-v12 icon (asset path or Material code point) to a key.
  static String legacyToKey({String? iconPath, int? iconCode}) {
    if (iconPath != null && iconPath.isNotEmpty) {
      final parts = iconPath.split('/');
      final file = parts.last.toLowerCase();
      for (final kw in _legacyKeywords) {
        if (file.contains(kw.key)) return kw.value;
      }
      if (parts.length >= 2) {
        final folder = _legacyFolders[parts[parts.length - 2]];
        if (folder != null) return folder;
      }
    }
    return fallbackKey;
  }
}
