// Spelling help for Cari (FR-023): "Mungkin maksudnya “kopi”?".

/// Edit distance between [a] and [b] (insert / delete / substitute = 1).
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost]
          .reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// Closest word in [vocabulary] within [maxDistance] edits of [query]
/// (case-insensitive), or null. Exact matches are not suggestions.
String? suggestSpelling(String query, Iterable<String> vocabulary,
    {int maxDistance = 2}) {
  final q = query.trim().toLowerCase();
  if (q.length < 3) return null;
  String? best;
  var bestDistance = maxDistance + 1;
  for (final raw in vocabulary) {
    final word = raw.trim().toLowerCase();
    if (word.isEmpty || word == q) continue;
    final d = levenshtein(q, word);
    if (d < bestDistance ||
        (d == bestDistance && best != null && word.length < best.length)) {
      bestDistance = d;
      best = word;
    }
  }
  return bestDistance <= maxDistance ? best : null;
}

/// Splits [text] into words for the suggestion vocabulary.
Iterable<String> wordsOf(String text) => text
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9à-ÿ]+'))
    .where((w) => w.length >= 3);
