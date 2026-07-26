class TransactionModel {
  int? id;
  int? amount;
  DateTime? date;
  String? note;
  String? type; // "pengeluaran" or "pemasukan"
  int? categoryId;
  String? categoryName;
  int? accountId;
  String? accountName;
  int? destinationAccountId;
  String? destinationAccountName;
  int? categoryIconCode;
  int? categoryColorVal;

  TransactionModel({
    this.id,
    this.amount,
    this.date,
    this.note,
    this.type,
    this.categoryId,
    this.categoryName,
    this.accountId,
    this.accountName,
    this.destinationAccountId,
    this.destinationAccountName,
    this.categoryIconCode,
    this.categoryColorVal,
  });

  TransactionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    amount = json['amount'];
    date = json['date'] != null ? DateTime.parse(json['date']) : null;
    note = json['note'];
    type = json['type'];
    categoryId = json['category_id'];
    categoryName = json['categoryName']; // Filled via JOIN
    accountId = json['account_id'];
    accountName = json['accountName']; // Filled via JOIN
    destinationAccountId = json['destination_account_id'];
    destinationAccountName = json['destinationAccountName']; // Filled via JOIN
    categoryIconCode = json['categoryIconCode'];
    categoryColorVal = json['categoryColorVal'];
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
    data['category_id'] = categoryId;
    data['account_id'] = accountId;
    data['destination_account_id'] = destinationAccountId;
    return data;
  }
}
