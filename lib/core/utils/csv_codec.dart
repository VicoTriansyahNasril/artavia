// Pure CSV (RFC 4180 subset) used by export and import.

String _escape(String value, String delimiter) {
  final needsQuotes = value.contains('"') ||
      value.contains(delimiter) ||
      value.contains(RegExp(r'[\r\n]'));
  final escaped = value.replaceAll('"', '""');
  return needsQuotes ? '"$escaped"' : escaped;
}

/// Rows → CSV text with CRLF line ends.
String encodeCsv(List<List<String>> rows, {String delimiter = ','}) => rows
    .map((r) => r.map((v) => _escape(v, delimiter)).join(delimiter))
    .join('\r\n');

/// Guesses `,` or `;` from the first line (Excel in Indonesian locale uses `;`).
String detectDelimiter(String text) {
  final firstLine = text.split(RegExp(r'\r?\n')).first;
  return ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length
      ? ';'
      : ',';
}

/// Parses CSV text into rows; handles quoted delimiters, quotes, newlines
/// and a UTF-8 BOM. Blank lines are dropped.
List<List<String>> decodeCsv(String text, {String? delimiter}) {
  final input = text.startsWith('﻿') ? text.substring(1) : text;
  final sep = delimiter ?? detectDelimiter(input);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    if (inQuotes) {
      if (c != '"') {
        field.write(c);
      } else if (i + 1 < input.length && input[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        inQuotes = false;
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == sep) {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows.where((r) => r.any((v) => v.trim().isNotEmpty)).toList();
}
