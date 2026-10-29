import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SC-008 / constitution III: every UI color comes from
/// `lib/widgets/commons/colors.dart`.
void main() {
  test('no Color(0x…) or Colors.* outside colors.dart', () {
    final rawColor = RegExp(r'\bColor\(0x');
    final materialColor = RegExp(r'\bColors\.(?!transparent\b)\w+');
    final offenders = <String>[];

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path
            .replaceAll(r'\', '/')
            .endsWith('lib/widgets/commons/colors.dart'));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (rawColor.hasMatch(line) || materialColor.hasMatch(line)) {
          offenders.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
