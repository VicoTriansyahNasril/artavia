import 'package:intl/intl.dart';

class DateFormatter {
  static String formatWithRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    
    final inputDate = DateTime(date.year, date.month, date.day);
    
    final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(date);

    if (inputDate == today) {
      return 'Hari Ini ($formattedDate)';
    } else if (inputDate == yesterday) {
      return 'Kemarin ($formattedDate)';
    } else if (inputDate == tomorrow) {
      return 'Besok ($formattedDate)';
    } else {
      return formattedDate;
    }
  }
}
