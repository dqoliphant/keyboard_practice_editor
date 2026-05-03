const int kGuitarStrings = 6;
const int kGuitarFretRows = 4;

const List<String> kGuitarStringNames = ['E', 'A', 'D', 'G', 'B', 'e'];

class GuitarChordData {
  // -1 = muted, 0 = open, 1–22 = fret number pressed
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
}
