import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Minimal .xlsx reader/writer on `archive` + `xml` (research R8).
///
/// Writes one worksheet per entry with numbers as numeric cells and text as
/// inline strings. Reads shared strings, inline strings, numbers and
/// booleans from any workbook; formatting is ignored.
abstract final class XlsxCodec {
  static const _ns =
      'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  static const _rel =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

  // ─── Write ───────────────────────────────────────────────────────────────

  /// [sheets]: sheet name → rows; cells are `num`, `String` or null.
  static Uint8List encode(Map<String, List<List<Object?>>> sheets) {
    final archive = Archive();
    void add(String path, String xml) {
      final bytes = utf8.encode(xml);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    final names = sheets.keys.toList();
    add('[Content_Types].xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
${[
      for (var i = 1; i <= names.length; i++)
        '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
    ].join('\n')}
</Types>''');
    add('_rels/.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="$_rel/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''');
    add('xl/workbook.xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="$_ns" xmlns:r="$_rel"><sheets>
${[
      for (var i = 0; i < names.length; i++)
        '<sheet name="${_attr(names[i])}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'
    ].join()}
</sheets></workbook>''');
    add('xl/_rels/workbook.xml.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
${[
      for (var i = 1; i <= names.length; i++)
        '<Relationship Id="rId$i" Type="$_rel/worksheet" Target="worksheets/sheet$i.xml"/>'
    ].join()}
<Relationship Id="rId${names.length + 1}" Type="$_rel/styles" Target="styles.xml"/>
</Relationships>''');
    add('xl/styles.xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="$_ns"><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>
<fills count="1"><fill><patternFill patternType="none"/></fill></fills><borders count="1"><border/></borders>
<cellStyleXfs count="1"><xf/></cellStyleXfs><cellXfs count="2"><xf/><xf fontId="1" applyFont="1"/></cellXfs></styleSheet>''');
    for (var i = 0; i < names.length; i++) {
      add('xl/worksheets/sheet${i + 1}.xml', _sheetXml(sheets[names[i]]!));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static String _sheetXml(List<List<Object?>> rows) {
    final b = StringBuffer(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="$_ns"><sheetData>');
    for (var r = 0; r < rows.length; r++) {
      b.write('<row r="${r + 1}">');
      for (var c = 0; c < rows[r].length; c++) {
        final v = rows[r][c];
        if (v == null) continue;
        final ref = '${columnName(c)}${r + 1}';
        final style = r == 0 ? ' s="1"' : '';
        if (v is num) {
          b.write('<c r="$ref"$style><v>$v</v></c>');
        } else {
          b.write('<c r="$ref" t="inlineStr"$style><is><t xml:space="preserve">'
              '${_text(v.toString())}</t></is></c>');
        }
      }
      b.write('</row>');
    }
    b.write('</sheetData></worksheet>');
    return b.toString();
  }

  static String _text(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _attr(String s) => _text(s).replaceAll('"', '&quot;');

  /// 0 → A, 25 → Z, 26 → AA.
  static String columnName(int index) {
    var n = index + 1;
    final out = StringBuffer();
    final chars = <String>[];
    while (n > 0) {
      final m = (n - 1) % 26;
      chars.insert(0, String.fromCharCode(65 + m));
      n = (n - 1) ~/ 26;
    }
    out.writeAll(chars);
    return out.toString();
  }

  static int columnIndex(String ref) {
    var n = 0;
    for (final ch in ref.codeUnits) {
      if (ch < 65 || ch > 90) break;
      n = n * 26 + (ch - 64);
    }
    return n - 1;
  }

  // ─── Read ────────────────────────────────────────────────────────────────

  /// Sheet name → rows of cell text (numbers as their XML value).
  static Map<String, List<List<String>>> decode(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    String? read(String path) {
      final f = archive.findFile(path);
      return f == null ? null : utf8.decode(f.content as List<int>);
    }

    final workbook = read('xl/workbook.xml');
    if (workbook == null) throw const FormatException('Bukan file Excel');
    final rels =
        XmlDocument.parse(read('xl/_rels/workbook.xml.rels') ?? '<r/>');
    final targets = {
      for (final r in rels.findAllElements('Relationship'))
        r.getAttribute('Id'): r.getAttribute('Target'),
    };
    final shared = <String>[];
    final sst = read('xl/sharedStrings.xml');
    if (sst != null) {
      for (final si in XmlDocument.parse(sst).findAllElements('si')) {
        shared.add(si.findAllElements('t').map((t) => t.innerText).join());
      }
    }

    final result = <String, List<List<String>>>{};
    for (final sheet in XmlDocument.parse(workbook).findAllElements('sheet')) {
      final id = sheet.attributes
          .where((a) => a.name.local == 'id')
          .map((a) => a.value)
          .firstOrNull;
      var target = targets[id] ?? '';
      if (target.startsWith('/')) target = target.substring(1);
      if (!target.startsWith('xl/')) target = 'xl/$target';
      final xml = read(target);
      if (xml == null) continue;
      result[sheet.getAttribute('name') ?? target] = _rows(xml, shared);
    }
    return result;
  }

  static List<List<String>> _rows(String xml, List<String> shared) {
    final rows = <List<String>>[];
    for (final row in XmlDocument.parse(xml).findAllElements('row')) {
      final cells = <String>[];
      for (final c in row.findElements('c')) {
        final ref = c.getAttribute('r');
        final col = ref == null ? cells.length : columnIndex(ref);
        while (cells.length < col) {
          cells.add('');
        }
        final type = c.getAttribute('t');
        final v = c.getElement('v')?.innerText ?? '';
        final text = switch (type) {
          's' => shared[int.tryParse(v) ?? 0],
          'inlineStr' => c.findAllElements('t').map((t) => t.innerText).join(),
          'b' => v == '1' ? 'TRUE' : 'FALSE',
          _ => v,
        };
        if (col < cells.length) {
          cells[col] = text;
        } else {
          cells.add(text);
        }
      }
      rows.add(cells);
    }
    return rows.where((r) => r.any((v) => v.trim().isNotEmpty)).toList();
  }
}
