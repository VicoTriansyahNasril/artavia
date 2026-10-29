import 'package:flutter_test/flutter_test.dart';
import 'package:artavia/core/utils/text_match.dart';

void main() {
  test('levenshtein basics', () {
    expect(levenshtein('kopi', 'kopi'), 0);
    expect(levenshtein('kopiii', 'kopi'), 2);
    expect(levenshtein('bensin', 'bensn'), 1);
    expect(levenshtein('', 'abc'), 3);
  });

  test('"kopiii" suggests "kopi"', () {
    expect(
        suggestSpelling('kopiii', ['Kopi', 'Makan siang', 'kopiko']), 'kopi');
  });

  test('nothing close enough, too short, or exact → null', () {
    expect(suggestSpelling('xyzxyz', ['kopi', 'makan']), isNull);
    expect(suggestSpelling('ko', ['kopi']), isNull);
    expect(suggestSpelling('kopi', ['kopi']), isNull);
  });

  test('wordsOf splits notes into words of 3+ letters', () {
    expect(wordsOf('Kopi susu di BCA'), ['kopi', 'susu', 'bca']);
  });
}
