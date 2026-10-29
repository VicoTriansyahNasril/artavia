/// Represents a single financial account (wallet, bank, e-wallet, etc.)
class AccountModel {
  final int? id;
  final String name;
  final String type;
  final int balance;
  final String currencyCode;
  final int iconCode;
  final String? iconPath;
  final int colorVal;
  final bool isExcluded;
  final String? iconKey;
  final int sortOrder;
  final bool isArchived;

  /// Kartu Kredit only.
  final int? creditLimit;
  final int? dueDay;

  const AccountModel({
    this.id,
    required this.name,
    required this.type,
    this.balance = 0,
    this.currencyCode = 'IDR',
    required this.iconCode,
    this.iconPath,
    required this.colorVal,
    this.isExcluded = false,
    this.iconKey,
    this.sortOrder = 0,
    this.isArchived = false,
    this.creditLimit,
    this.dueDay,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'Lainnya',
      balance: json['balance'] as int? ?? 0,
      currencyCode: json['currency_code'] as String? ?? 'IDR',
      iconCode: json['icon_code'] as int? ?? 0xe4fc,
      iconPath: json['icon_path'] as String?,
      colorVal: json['color_val'] as int? ?? 0xFFE0B25C,
      isExcluded: (json['is_excluded'] as int? ?? 0) == 1,
      iconKey: json['icon_key'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isArchived: (json['is_archived'] as int? ?? 0) == 1,
      creditLimit: json['credit_limit'] as int?,
      dueDay: json['due_day'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency_code': currencyCode,
      'icon_code': iconCode,
      'icon_path': iconPath,
      'color_val': colorVal,
      'is_excluded': isExcluded ? 1 : 0,
      'icon_key': iconKey,
      'sort_order': sortOrder,
      'is_archived': isArchived ? 1 : 0,
      'credit_limit': creditLimit,
      'due_day': dueDay,
    };
  }

  AccountModel copyWith({
    int? id,
    String? name,
    String? type,
    int? balance,
    String? currencyCode,
    int? iconCode,
    String? iconPath,
    int? colorVal,
    bool? isExcluded,
    String? iconKey,
    int? sortOrder,
    bool? isArchived,
    int? creditLimit,
    int? dueDay,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currencyCode: currencyCode ?? this.currencyCode,
      iconCode: iconCode ?? this.iconCode,
      iconPath: iconPath ?? this.iconPath,
      colorVal: colorVal ?? this.colorVal,
      isExcluded: isExcluded ?? this.isExcluded,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      creditLimit: creditLimit ?? this.creditLimit,
      dueDay: dueDay ?? this.dueDay,
    );
  }
}
