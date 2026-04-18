import 'dart:convert';

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

  // Which of the 12 grid slots are occupied (have a visible measure)
  final Set<int> occupiedSlots;

  PracticeSheet({Set<int>? occupiedSlots})
      : occupiedSlots = occupiedSlots ?? {0},
        state = List.generate(
          kMeasureCount,
          (_) => List.generate(
            kKeyboardsPerMeasure,
            (_) => List.filled(kSemitones, false),
          ),
        );

  PracticeSheet.fromState(this.state, {required Set<int> occupiedSlots})
      : occupiedSlots = Set.unmodifiable(occupiedSlots);

  void toggle(int slotIdx, int keyboard, int semitone) {
    state[slotIdx][keyboard][semitone] = !state[slotIdx][keyboard][semitone];
  }

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

  PracticeSheet withSlotAdded(int slotIdx) {
    // Clear that slot's key state so it starts fresh
    final newState = List.generate(
      kMeasureCount,
      (mi) => List.generate(
        kKeyboardsPerMeasure,
        (ki) => mi == slotIdx
            ? List.filled(kSemitones, false)
            : List<bool>.from(state[mi][ki]),
      ),
    );
    return PracticeSheet.fromState(
      newState,
      occupiedSlots: {...occupiedSlots, slotIdx},
    );
  }

  Map<String, dynamic> toJson() => {
        'occupiedSlots': (occupiedSlots.toList()..sort()),
        'state': state
            .map((m) => m.map((k) => k.map((v) => v ? 1 : 0).toList()).toList())
            .toList(),
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
    return PracticeSheet.fromState(s, occupiedSlots: slots);
  }

  String toJsonString() => jsonEncode(toJson());

  factory PracticeSheet.fromJsonString(String s) =>
      PracticeSheet.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
