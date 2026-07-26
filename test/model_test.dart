import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/model/transaction_model.dart';

void main() {
  group('TransactionModel Test', () {
    test('Should parse from JSON correctly', () {
      final json = {
        'id': 123,
        'amount': 50000,
        'date': '2023-10-01T12:00:00.000Z',
        'note': 'Makan siang',
        'type': 'pengeluaran',
        'category_id': 1,
        'categoryName': 'Makanan',
        'account_id': 1,
        'accountName': 'CASH',
      };

      final model = TransactionModel.fromJson(json);

      expect(model.id, 123);
      expect(model.amount, 50000);
      expect(model.date?.year, 2023);
      expect(model.note, 'Makan siang');
      expect(model.type, 'pengeluaran');
      expect(model.categoryId, 1);
      expect(model.categoryName, 'Makanan');
      expect(model.accountId, 1);
      expect(model.accountName, 'CASH');
    });

    test('Should handle null values gracefully', () {
      final json = <String, dynamic>{};
      final model = TransactionModel.fromJson(json);

      expect(model.id, isNull);
      expect(model.amount, isNull);
      expect(model.date, isNull);
      expect(model.note, isNull);
    });

    test('Should serialize to JSON correctly', () {
      final model = TransactionModel(
        id: 456,
        amount: 100000,
        date: DateTime.utc(2023, 11, 2),
        note: 'Gaji',
        type: 'pemasukan',
        categoryId: 1,
        categoryName: 'Gaji',
        accountId: 2,
        accountName: 'BCA',
      );

      final json = model.toJson();

      expect(json['id'], 456);
      expect(json['amount'], 100000);
      expect(json['date'], '2023-11-02T00:00:00.000Z');
      expect(json['note'], 'Gaji');
      expect(json['category_id'], 1);
      expect(json['account_id'], 2);
    });
  });
}
