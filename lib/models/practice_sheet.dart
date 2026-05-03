import 'dart:convert';
import 'chord_detector.dart';
import 'guitar_chord_data.dart';

const int kMeasureCount = 12;
const int kKeyboardsPerMeasure = 2;
const int kKeysPerKeyboard = 28; // 14 white + 10 black keys (stored as 28-slot array)

// Key layout for 2 octaves: indices 0–27 map to piano keys
// White key indices: 0,2,4,5,7,9,11,12,14,16,17,19,21,23 (14 keys)
// Black key indices: 1,3,6,8,10,13,15,18,20,22 (10 keys)
// Index 24 = C5 white, 25=D5, 26=E5, 27=F5 — wait, let me use a flat 28-slot
// Actually: 2 octaves = 24 semitones, C to B = 12 semitones each
// Slots 0–11: octave 1 (C4 to B4), slots 12–23: octave 2 (C5 to B5)
// But we only need 14 white keys + 10 black = 24 semitone positions
// Let's use 24 slots (semitone index 0–23)

const int kSemitones = 24; // 2 octaves

// Returns true if the semitone index is a black key
bool isBlackKey(int semitone) {
  final int mod = semitone % 12;
  return mod == 1 || mod == 3 || mod == 6 || mod == 8 || mod == 10;
}

class PracticeSheet {
  // [slot][keyboard][semitone] = active? — always 12 slots allocated
  final List<List<List<bool>>> state;

  // [slot][keyboard][semitone] = finger number 1–5, or 0 for none
  final List<List<List<int>>> fingerNumbers;

  // Which of the 12 grid slots are occupied (have a visible measure)
  final Set<int> occupiedSlots;

  final String sectionLabel;

  // User-selected chord label per slot; overrides auto-detection when valid.
  final Map<int, String> chordOverrides;

  // Guitar chord data per slot; non-null = slot is in guitar mode.
  final List<GuitarChordData?> guitarChords;

  PracticeSheet({Set<int>? occupiedSlots, this.sectionLabel = ''})
      : occupiedSlots = occupiedSlots ?? {0},
        chordOverrides = const {},
        guitarChords = List<GuitarChordData?>.filled(kMeasureCount, null, growable: false),
        state = List.generate(
          kMeasureCount,
          (_) => List.generate(
            kKeyboardsPerMeasure,
            (_) => List.filled(kSemitones, false),
          ),
        ),
        fingerNumbers = List.generate(
          kMeasureCount,
          (_) => List.generate(
            kKeyboardsPerMeasure,
            (_) => List.filled(kSemitones, 0),
          ),
        );

  PracticeSheet.fromState(
    this.state, {
    required Set<int> occupiedSlots,
    this.sectionLabel = '',
    Map<int, String>? chordOverrides,
    List<List<List<int>>>? fingerNumbers,
    List<GuitarChordData?>? guitarChords,
  })  : occupiedSlots = Set.unmodifiable(occupiedSlots),
        chordOverrides = Map.unmodifiable(chordOverrides ?? {}),
        fingerNumbers = fingerNumbers ??
            List.generate(
              kMeasureCount,
              (_) => List.generate(
                kKeyboardsPerMeasure,
                (_) => List.filled(kSemitones, 0),
              ),
            ),
        guitarChords = guitarChords ?? List<GuitarChordData?>.filled(kMeasureCount, null, growable: false);

  // ---------------------------------------------------------------------------
  // Piano key mutations (in-place, like mutable state)

  void toggle(int slotIdx, int keyboard, int semitone) {
    if (fingerNumbers[slotIdx][keyboard][semitone] > 0) {
      fingerNumbers[slotIdx][keyboard][semitone] = 0;
      state[slotIdx][keyboard][semitone] = false;
    } else {
      state[slotIdx][keyboard][semitone] = !state[slotIdx][keyboard][semitone];
    }
  }

  // Cycles finger number for a key: 0 → 1 → 2 → 3 → 4 → 5 → 0
  void cycleFinger(int slotIdx, int keyboard, int semitone) {
    final cur = fingerNumbers[slotIdx][keyboard][semitone];
    fingerNumbers[slotIdx][keyboard][semitone] = cur >= 5 ? 0 : cur + 1;
  }

  // ---------------------------------------------------------------------------
  // Guitar chord mutations (in-place)

  bool isGuitarSlot(int slotIdx) => guitarChords[slotIdx] != null;

  void setGuitarChordData(int slotIdx, GuitarChordData? data) {
    guitarChords[slotIdx] = data;
  }

  void toggleGuitarFret(int slotIdx, int stringIdx, int fretAbsolute) {
    final data = guitarChords[slotIdx];
    if (data == null) return;
    final newFrets = List<int>.from(data.frets);
    final newFingers = List<int>.from(data.fingers);
    if (newFrets[stringIdx] == fretAbsolute) {
      newFrets[stringIdx] = 0;
      newFingers[stringIdx] = 0;
    } else {
      newFrets[stringIdx] = fretAbsolute;
    }
    guitarChords[slotIdx] = data.copyWith(frets: newFrets, fingers: newFingers);
  }

  void cycleGuitarFinger(int slotIdx, int stringIdx) {
    final data = guitarChords[slotIdx];
    if (data == null || data.frets[stringIdx] <= 0) return;
    final newFingers = List<int>.from(data.fingers);
    final cur = newFingers[stringIdx];
    newFingers[stringIdx] = cur >= 4 ? 0 : cur + 1;
    guitarChords[slotIdx] = data.copyWith(fingers: newFingers);
  }

  // Cycles the header marker for a string:
  //   fretted → X  (mute a fretted string)
  //   O (0)   → X (-1)
  //   X (-1)  → nothing (-2)
  //   nothing → O (0)
  void toggleGuitarStringMute(int slotIdx, int stringIdx) {
    final data = guitarChords[slotIdx];
    if (data == null) return;
    final newFrets = List<int>.from(data.frets);
    final newFingers = List<int>.from(data.fingers);
    final cur = newFrets[stringIdx];
    if (cur > 0) {
      newFrets[stringIdx] = -1;
      newFingers[stringIdx] = 0;
    } else if (cur == 0) {
      newFrets[stringIdx] = -1;
    } else if (cur == -1) {
      newFrets[stringIdx] = -2;
    } else {
      newFrets[stringIdx] = 0; // -2 → O
    }
    guitarChords[slotIdx] = data.copyWith(frets: newFrets, fingers: newFingers);
  }

  void setGuitarChordName(int slotIdx, String name) {
    final data = guitarChords[slotIdx];
    if (data == null) return;
    guitarChords[slotIdx] = data.copyWith(chordName: name);
  }

  void shiftGuitarStartFret(int slotIdx, int delta) {
    final data = guitarChords[slotIdx];
    if (data == null) return;
    final newStart = (data.startFret + delta).clamp(1, 20);
    guitarChords[slotIdx] = data.copyWith(startFret: newStart);
  }

  // ---------------------------------------------------------------------------
  // Read helpers

  /// Display number for an occupied slot (1-based rank among occupied slots).
  int measureNumberForSlot(int slotIdx) {
    final sorted = occupiedSlots.toList()..sort();
    return sorted.indexOf(slotIdx) + 1;
  }

  /// First grid slot (0–11) that is not occupied, or -1 if all full.
  int get firstUnoccupiedSlot {
    for (int i = 0; i < kMeasureCount; i++) {
      if (!occupiedSlots.contains(i)) return i;
    }
    return -1;
  }

  /// The active chord label for a slot: uses the stored override if it is still
  /// a valid alternative for the current keys, otherwise falls back to the first
  /// auto-detected chord.
  String? activeChordForSlot(int slotIdx) {
    final all = detectAllChords(state[slotIdx]);
    if (all.isEmpty) return null;
    final override = chordOverrides[slotIdx];
    if (override != null && all.contains(override)) return override;
    return all.first;
  }

  // ---------------------------------------------------------------------------
  // Immutable structural mutations

  PracticeSheet withSectionLabel(String label) => PracticeSheet.fromState(state,
      occupiedSlots: occupiedSlots,
      sectionLabel: label,
      chordOverrides: chordOverrides,
      fingerNumbers: fingerNumbers,
      guitarChords: guitarChords);

  PracticeSheet withSlotRemoved(int slotIdx) {
    final newSlots = Set<int>.from(occupiedSlots)..remove(slotIdx);
    final newOverrides = Map<int, String>.from(chordOverrides)..remove(slotIdx);
    return PracticeSheet.fromState(state,
        occupiedSlots: newSlots,
        sectionLabel: sectionLabel,
        chordOverrides: newOverrides,
        fingerNumbers: fingerNumbers,
        guitarChords: guitarChords);
  }

  PracticeSheet withSlotAdded(int slotIdx) {
    final newState = List.generate(
      kMeasureCount,
      (mi) => List.generate(
        kKeyboardsPerMeasure,
        (ki) => mi == slotIdx
            ? List.filled(kSemitones, false)
            : List<bool>.from(state[mi][ki]),
      ),
    );
    final newFingers = List.generate(
      kMeasureCount,
      (mi) => List.generate(
        kKeyboardsPerMeasure,
        (ki) => mi == slotIdx
            ? List.filled(kSemitones, 0)
            : List<int>.from(fingerNumbers[mi][ki]),
      ),
    );
    // Clear guitar data for the new slot (new slots start in piano mode)
    final newGuitar = List<GuitarChordData?>.from(guitarChords);
    newGuitar[slotIdx] = null;
    return PracticeSheet.fromState(
      newState,
      occupiedSlots: {...occupiedSlots, slotIdx},
      sectionLabel: sectionLabel,
      chordOverrides: chordOverrides,
      fingerNumbers: newFingers,
      guitarChords: newGuitar,
    );
  }

  PracticeSheet withChordOverride(int slotIdx, String chord) {
    final newOverrides = Map<int, String>.from(chordOverrides)..[slotIdx] = chord;
    return PracticeSheet.fromState(state,
        occupiedSlots: occupiedSlots,
        sectionLabel: sectionLabel,
        chordOverrides: newOverrides,
        fingerNumbers: fingerNumbers,
        guitarChords: guitarChords);
  }

  // ---------------------------------------------------------------------------
  // Serialization

  bool get _hasFingerNumbers =>
      fingerNumbers.any((m) => m.any((k) => k.any((v) => v > 0)));

  bool get _hasGuitarChords => guitarChords.any((g) => g != null);

  Map<String, dynamic> toJson() => {
        'occupiedSlots': (occupiedSlots.toList()..sort()),
        'sectionLabel': sectionLabel,
        if (chordOverrides.isNotEmpty)
          'chordOverrides':
              chordOverrides.map((k, v) => MapEntry(k.toString(), v)),
        'state': state
            .map((m) => m.map((k) => k.map((v) => v ? 1 : 0).toList()).toList())
            .toList(),
        if (_hasFingerNumbers)
          'fingerNumbers': fingerNumbers
              .map((m) => m.map((k) => k.toList()).toList())
              .toList(),
        if (_hasGuitarChords)
          'guitarChords': guitarChords.map((g) => g?.toJson()).toList(),
      };

  factory PracticeSheet.fromJson(Map<String, dynamic> json) {
    final raw = json['state'] as List;
    final s = List.generate(
      kMeasureCount,
      (mi) => List.generate(
        kKeyboardsPerMeasure,
        (ki) => List.generate(
          kSemitones,
          (si) => (raw[mi][ki][si] as int) == 1,
        ),
      ),
    );
    final slots = json['occupiedSlots'] != null
        ? Set<int>.from((json['occupiedSlots'] as List).cast<int>())
        : Set<int>.from(List.generate(kMeasureCount, (i) => i));
    final rawOverrides = json['chordOverrides'] as Map<String, dynamic>?;
    final overrides = rawOverrides != null
        ? rawOverrides.map((k, v) => MapEntry(int.parse(k), v as String))
        : <int, String>{};
    final rawFingers = json['fingerNumbers'] as List?;
    final fingers = rawFingers != null
        ? List.generate(
            kMeasureCount,
            (mi) => List.generate(
              kKeyboardsPerMeasure,
              (ki) => List.generate(
                kSemitones,
                (si) => (rawFingers[mi][ki][si] as int),
              ),
            ),
          )
        : null;
    final rawGuitar = json['guitarChords'] as List?;
    final guitar = rawGuitar != null
        ? List<GuitarChordData?>.from(rawGuitar.map((g) =>
            g != null ? GuitarChordData.fromJson(g as Map<String, dynamic>) : null))
        : null;
    return PracticeSheet.fromState(s,
        occupiedSlots: slots,
        sectionLabel: json['sectionLabel'] as String? ?? '',
        chordOverrides: overrides,
        fingerNumbers: fingers,
        guitarChords: guitar);
  }

  String toJsonString() => jsonEncode(toJson());

  factory PracticeSheet.fromJsonString(String s) =>
      PracticeSheet.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
