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

/// Indonesian month/day names that do not depend on intl locale data,
/// so they are safe in tests and before `initializeDateFormatting`.
class IdNames {
  static const monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  static const monthsLong = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  static const daysShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const daysLong = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Weekday full name (Monday = Senin).
  static String dayLong(DateTime date) => daysLong[date.weekday - 1];

  static String monthShort(int month) => monthsShort[month - 1];
  static String monthLong(int month) => monthsLong[month - 1];

  /// Weekday short name for a date (Monday = Sen).
  static String dayShort(DateTime date) => daysShort[date.weekday - 1];

  /// e.g. "5 Okt 2026"
  static String shortDate(DateTime date) =>
      '${date.day} ${monthShort(date.month)} ${date.year}';
}
