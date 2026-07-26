class TransactionModel {
  String? id;
  int? amount;
  DateTime? date;
  String? note;
  String? type; // "pengeluaran" or "pemasukan"
  String? categoryName;
  String? account;

  TransactionModel({
    this.id,
    this.amount,
    this.date,
    this.note,
    this.type,
    this.categoryName,
    this.account,
  });

  TransactionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    amount = json['amount'];
    date = json['date'] != null ? DateTime.parse(json['date']) : null;
    note = json['note'];
    type = json['type'];
    categoryName = json['categoryName'];
    account = json['account'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['amount'] = amount;
    if (date != null) {
      data['date'] = date!.toIso8601String();
    }
    data['note'] = note;
    data['type'] = type;
    data['categoryName'] = categoryName;
    return data;
  }
}
