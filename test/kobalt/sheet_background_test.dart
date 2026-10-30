import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `Get.bottomSheet` paints a transparent background unless told otherwise;
/// sheets must open through `showSheet` (lib/widgets/kobalt/sheet.dart).
void main() {
  test('no Get.bottomSheet outside sheet.dart', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path
            .replaceAll(r'\', '/')
            .endsWith('lib/widgets/kobalt/sheet.dart'));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('Get.bottomSheet')) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
