/// Represents a single financial account (wallet, bank, e-wallet, etc.)
class AccountModel {
  final int? id;
  final String name;
  final String type;
  final int balance;
  final String currencyCode;
  final int iconCode;
  final int colorVal;
  final bool isExcluded;

  const AccountModel({
    this.id,
    required this.name,
    required this.type,
    this.balance = 0,
    this.currencyCode = 'IDR',
    required this.iconCode,
    required this.colorVal,
    this.isExcluded = false,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'Lainnya',
      balance: json['balance'] as int? ?? 0,
      currencyCode: json['currency_code'] as String? ?? 'IDR',
      iconCode: json['icon_code'] as int? ?? 0xe4fc,
      colorVal: json['color_val'] as int? ?? 0xFFFFCA28,
      isExcluded: (json['is_excluded'] as int? ?? 0) == 1,
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
      'color_val': colorVal,
      'is_excluded': isExcluded ? 1 : 0,
    };
  }

  AccountModel copyWith({
    int? id,
    String? name,
    String? type,
    int? balance,
    String? currencyCode,
    int? iconCode,
    int? colorVal,
    bool? isExcluded,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currencyCode: currencyCode ?? this.currencyCode,
      iconCode: iconCode ?? this.iconCode,
      colorVal: colorVal ?? this.colorVal,
      isExcluded: isExcluded ?? this.isExcluded,
    );
  }
}
