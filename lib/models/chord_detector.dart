const List<String> _noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
];

// Flat enharmonic spellings for the five black keys.
const Map<int, String> _flatNames = {
  1: 'Db', 3: 'Eb', 6: 'Gb', 8: 'Ab', 10: 'Bb',
};

// Ordered most-specific first so longer chords match before subsets
const List<(Set<int>, String)> _chordPatterns = [
  // 5-note
  ({0, 2, 4, 7, 11}, 'maj9'),
  ({0, 2, 4, 7, 10}, '9'),
  ({0, 2, 3, 7, 10}, 'm9'),
  // 4-note
  ({0, 4, 7, 11}, 'maj7'),
  ({0, 4, 7, 10}, '7'),
  ({0, 3, 7, 10}, 'm7'),
  ({0, 3, 7, 11}, 'mMaj7'),
  ({0, 3, 6, 9},  'dim7'),
  ({0, 3, 6, 10}, 'm7♭5'),
  ({0, 4, 8, 10}, 'aug7'),
  ({0, 4, 7, 9},  '6'),
  ({0, 3, 7, 9},  'm6'),
  ({0, 2, 4, 7},  'add9'),
  ({0, 2, 3, 7},  'madd9'),
  // 3-note
  ({0, 4, 7}, ''),
  ({0, 3, 7}, 'm'),
  ({0, 3, 6}, 'dim'),
  ({0, 4, 8}, 'aug'),
  ({0, 2, 7}, 'sus2'),
  ({0, 5, 7}, 'sus4'),
  // 2-note
  ({0, 7}, '5'),
];

/// Returns a chord name (e.g. "Cm7", "F#maj7") for the combined active keys
/// across all keyboards in a measure, or null if no known chord matches.
String? detectChord(List<List<bool>> keyboards) {
  final all = detectAllChords(keyboards);
  return all.isEmpty ? null : all.first;
}

/// Returns every valid chord name for the given keyboards, including slash chord
/// variants when the bass note (lowest active key) differs from the chord root.
/// Root-position names appear before their slash variants. Multiple root matches
/// (e.g. Am7 vs C6 for the same notes) are all included.
List<String> detectAllChords(List<List<bool>> keyboards) {
  final pitchClasses = <int>{};
  int? bassClass; // pitch class of the lowest-indexed active key

  for (final kb in keyboards) {
    for (int i = 0; i < kb.length; i++) {
      if (kb[i]) {
        pitchClasses.add(i % 12);
        bassClass ??= i % 12;
      }
    }
  }

  if (pitchClasses.length < 2) return [];

  final results = <String>[];

  for (final (pattern, suffix) in _chordPatterns) {
    for (int root = 0; root < 12; root++) {
      final transposed = pattern.map((i) => (root + i) % 12).toSet();
      if (transposed.length == pitchClasses.length &&
          transposed.containsAll(pitchClasses)) {
        // Collect both enharmonic spellings for this root (one for natural/sharp,
        // one for flat if the root is a black key).
        final rootNames = [
          _noteNames[root],
          if (_flatNames.containsKey(root)) _flatNames[root]!,
        ];
        for (final rootName in rootNames) {
          final name = '$rootName$suffix';
          results.add(name);
          if (bassClass != null && bassClass != root) {
            final bassName = _flatNames[bassClass] ?? _noteNames[bassClass];
            results.add('$name/$bassName');
          }
        }
      }
    }
  }

  return results;
}
