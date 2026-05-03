const int kGuitarStrings = 6;
const int kGuitarFretRows = 4;

const List<String> kGuitarStringNames = ['E', 'A', 'D', 'G', 'B', 'e'];

class GuitarChordData {
  // -2 = no marker, -1 = muted (X), 0 = open (O), 1–22 = fret number pressed
  final List<int> frets;
  // 0 = no finger label, 1–4 = finger number
  final List<int> fingers;
  // 1 = open position (shows nut); >1 = higher position (shows "Xfr" label)
  final int startFret;
  final String chordName;

  GuitarChordData({
    required List<int> frets,
    required List<int> fingers,
    required this.startFret,
    required this.chordName,
  })  : frets = List.unmodifiable(frets),
        fingers = List.unmodifiable(fingers);

  factory GuitarChordData.blank() => GuitarChordData(
        frets: List<int>.filled(kGuitarStrings, 0),
        fingers: List<int>.filled(kGuitarStrings, 0),
        startFret: 1,
        chordName: '',
      );

  GuitarChordData copyWith({
    List<int>? frets,
    List<int>? fingers,
    int? startFret,
    String? chordName,
  }) =>
      GuitarChordData(
        frets: frets ?? List<int>.from(this.frets),
        fingers: fingers ?? List<int>.from(this.fingers),
        startFret: startFret ?? this.startFret,
        chordName: chordName ?? this.chordName,
      );

  Map<String, dynamic> toJson() => {
        'frets': List<int>.from(frets),
        'fingers': List<int>.from(fingers),
        'startFret': startFret,
        'chordName': chordName,
      };

  factory GuitarChordData.fromJson(Map<String, dynamic> json) =>
      GuitarChordData(
        frets: List<int>.from(json['frets'] as List),
        fingers: List<int>.from(json['fingers'] as List),
        startFret: json['startFret'] as int? ?? 1,
        chordName: json['chordName'] as String? ?? '',
      );

  // Converts a hovered string + fret to (keyboard, semitone) for GrandStaffWidget.
  // fretAbsolute == 0 means open string. Returns null if out of the staff range.
  //
  // Treble (keyboard 0): C4–B5  →  MIDI 60–83
  // Bass   (keyboard 1): C2–B3  →  MIDI 36–59
  static (int, int)? noteToStaff(int stringIdx, int fretAbsolute) {
    const openMidi = [40, 45, 50, 55, 59, 64];
    final midi = openMidi[stringIdx] + fretAbsolute;
    if (midi >= 60 && midi < 84) return (0, midi - 60);
    if (midi >= 36 && midi < 60) return (1, midi - 36);
    return null;
  }

  // Converts the sounding notes of this chord to the [2][24] bool array that
  // GrandStaffWidget expects.
  //
  // Standard tuning open-string MIDI notes: E2=40, A2=45, D3=50, G3=55, B3=59, E4=64
  //   Treble (keyboard 0): C4–B5  →  MIDI 60–83, semitone = midi - 60
  //   Bass   (keyboard 1): C2–B3  →  MIDI 36–59, semitone = midi - 36
  List<List<bool>> toStaffKeys() {
    const openMidi = [40, 45, 50, 55, 59, 64];
    final keys = List.generate(2, (_) => List.filled(24, false));
    for (int s = 0; s < kGuitarStrings; s++) {
      final fret = frets[s];
      if (fret < 0) continue; // muted or no marker
      final midi = openMidi[s] + fret;
      if (midi >= 60 && midi < 84) {
        keys[0][midi - 60] = true; // treble
      } else if (midi >= 36 && midi < 60) {
        keys[1][midi - 36] = true; // bass
      }
    }
    return keys;
  }
}
