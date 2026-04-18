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
  // [measure][keyboard][semitone] = active?
  final List<List<List<bool>>> state;
  final int activeMeasureCount;

  PracticeSheet({this.activeMeasureCount = 1})
      : state = List.generate(
          kMeasureCount,
          (_) => List.generate(
            kKeyboardsPerMeasure,
            (_) => List.filled(kSemitones, false),
          ),
        );

  PracticeSheet.fromState(this.state, {this.activeMeasureCount = 1});

  void toggle(int measure, int keyboard, int semitone) {
    state[measure][keyboard][semitone] = !state[measure][keyboard][semitone];
  }

  PracticeSheet withActiveMeasureCount(int count) =>
      PracticeSheet.fromState(state, activeMeasureCount: count);

  Map<String, dynamic> toJson() => {
        'activeMeasureCount': activeMeasureCount,
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
    final count = (json['activeMeasureCount'] as int?) ?? kMeasureCount;
    return PracticeSheet.fromState(s, activeMeasureCount: count);
  }

  String toJsonString() => jsonEncode(toJson());

  factory PracticeSheet.fromJsonString(String s) =>
      PracticeSheet.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
