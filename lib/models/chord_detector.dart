const List<String> _noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
];

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
  final pitchClasses = <int>{};
  for (final kb in keyboards) {
    for (int i = 0; i < kb.length; i++) {
      if (kb[i]) pitchClasses.add(i % 12);
    }
  }

  if (pitchClasses.length < 2) return null;

  for (final (pattern, suffix) in _chordPatterns) {
    for (int root = 0; root < 12; root++) {
      final transposed = pattern.map((i) => (root + i) % 12).toSet();
      if (transposed.length == pitchClasses.length &&
          transposed.containsAll(pitchClasses)) {
        return '${_noteNames[root]}$suffix';
      }
    }
  }

  return null;
}
