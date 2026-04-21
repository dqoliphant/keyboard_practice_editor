import 'package:flutter/material.dart';

enum StaffAccidental { sharp, flat }

// Layout constants
const double _kStepH = 8.0;
const double _kCenterY = 134.0; // y-coordinate of middle C (diatonic step 0)
const double _kPanelWidth = 148.0;
const double _kPanelHeight = 280.0;
const double _kStaffLeft = 34.0;
const double _kStaffRight = 132.0;
const double _kNoteX = 94.0;
const double _kNoteW = 12.0;
const double _kNoteH = 8.0;
const double _kLedgerHalfW = 10.0;
const double _kKeyX = 46.0; // center-x for key-signature symbols

double _stepToY(int step) => _kCenterY - step * _kStepH;

// Keyboard 0 (treble): semitone 0 = C4.  Keyboard 1 (bass): semitone 0 = C2.
// C2 is 2 octaves = 14 diatonic steps below C4.
const List<int> _kKbBaseStep = [0, -14];

// Natural semitone within octave → diatonic offset (0=C … 6=B).
const Map<int, int> _kSemiToDiatonic = {
  0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6,
};

// Accidental semitone → (noteNameOfSharpInterpretation, noteNameOfFlatInterpretation).
// Note names are 0-6 (C-B).
const Map<int, (int, int)> _kAccidentalNames = {
  1:  (0, 1), // C#/Db
  3:  (1, 2), // D#/Eb
  6:  (3, 4), // F#/Gb
  8:  (4, 5), // G#/Ab
  10: (5, 6), // A#/Bb
};

// Canonical diatonic step in treble staff (steps 2–10) for each note name.
const Map<int, int> _kTrebleKeySteps = {
  0: 7, 1: 8, 2: 9, 3: 10, 4: 4, 5: 5, 6: 6,
};

// Canonical diatonic step in bass staff (steps −10 to −2) for each note name.
const Map<int, int> _kBassKeySteps = {
  0: -7, 1: -6, 2: -5, 3: -4, 4: -3, 5: -2, 6: -8,
};

// ---------------------------------------------------------------------------

class GrandStaffWidget extends StatefulWidget {
  final List<List<bool>>? activeKeys; // [2][24] or null
  final int? hoveredKeyboard;
  final int? hoveredSemitone;

  const GrandStaffWidget({
    super.key,
    required this.activeKeys,
    required this.hoveredKeyboard,
    required this.hoveredSemitone,
  });

  @override
  State<GrandStaffWidget> createState() => _GrandStaffWidgetState();
}

class _GrandStaffWidgetState extends State<GrandStaffWidget> {
  Map<int, StaffAccidental> _keySig = const {};

  void _onTapDown(TapDownDetails details) {
    final step = ((_kCenterY - details.localPosition.dy) / _kStepH).round();
    // Dart's % on int is always non-negative when divisor is positive.
    final noteName = step % 7;
    setState(() {
      final updated = Map<int, StaffAccidental>.from(_keySig);
      final current = updated[noteName];
      if (current == null) {
        updated[noteName] = StaffAccidental.sharp;
      } else if (current == StaffAccidental.sharp) {
        updated[noteName] = StaffAccidental.flat;
      } else {
        updated.remove(noteName);
      }
      _keySig = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kPanelWidth,
      color: const Color(0xFFD8D8D8),
      child: Center(
        child: Container(
          width: _kPanelWidth,
          height: _kPanelHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: _onTapDown,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GrandStaffPainter(
                        activeKeys: widget.activeKeys,
                        hoveredKeyboard: widget.hoveredKeyboard,
                        hoveredSemitone: widget.hoveredSemitone,
                        keySig: _keySig,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 1,
                    top: _stepToY(10) - 8,
                    child: const IgnorePointer(
                      child: Text(
                        '\u{1D11E}', // 𝄞 MUSICAL SYMBOL G CLEF
                        style: TextStyle(
                            fontSize: 52, height: 1.0, color: Color(0xFF222222)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 3,
                    top: _stepToY(-2) - 4,
                    child: const IgnorePointer(
                      child: Text(
                        '\u{1D122}', // 𝄢 MUSICAL SYMBOL F CLEF
                        style: TextStyle(
                            fontSize: 36, height: 1.0, color: Color(0xFF222222)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _GrandStaffPainter extends CustomPainter {
  final List<List<bool>>? activeKeys;
  final int? hoveredKeyboard;
  final int? hoveredSemitone;
  final Map<int, StaffAccidental> keySig;

  static const List<int> _trebleLines = [2, 4, 6, 8, 10];
  static const List<int> _bassLines = [-2, -4, -6, -8, -10];

  _GrandStaffPainter({
    required this.activeKeys,
    required this.hoveredKeyboard,
    required this.hoveredSemitone,
    required this.keySig,
  });

  // Returns the diatonic step and whether a ♮ symbol is needed.
  // Returns null if the semitone cannot be displayed given the current key sig.
  ({int step, bool needsNatural})? _resolveNote(int keyboard, int semitone) {
    final oct = semitone ~/ 12;
    final semiInOct = semitone % 12;

    // Natural note
    final naturalDiatonic = _kSemiToDiatonic[semiInOct];
    if (naturalDiatonic != null) {
      final step = _kKbBaseStep[keyboard] + oct * 7 + naturalDiatonic;
      // ♮ needed when key sig marks this note name as sharp or flat
      return (step: step, needsNatural: keySig.containsKey(naturalDiatonic));
    }

    // Accidental note — displayable only if the key sig explains it
    final accInfo = _kAccidentalNames[semiInOct];
    if (accInfo != null) {
      final (sharpOf, flatOf) = accInfo;
      if (keySig[sharpOf] == StaffAccidental.sharp) {
        return (step: _kKbBaseStep[keyboard] + oct * 7 + sharpOf, needsNatural: false);
      }
      if (keySig[flatOf] == StaffAccidental.flat) {
        return (step: _kKbBaseStep[keyboard] + oct * 7 + flatOf, needsNatural: false);
      }
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawStaffLines(canvas);
    _drawBarline(canvas);
    _drawKeySig(canvas);
    _drawNotes(canvas);
  }

  void _drawStaffLines(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (final step in _trebleLines) {
      canvas.drawLine(
          Offset(_kStaffLeft, _stepToY(step)), Offset(_kStaffRight, _stepToY(step)), paint);
    }
    for (final step in _bassLines) {
      canvas.drawLine(
          Offset(_kStaffLeft, _stepToY(step)), Offset(_kStaffRight, _stepToY(step)), paint);
    }
  }

  void _drawBarline(Canvas canvas) {
    canvas.drawLine(
      Offset(_kStaffLeft, _stepToY(10)),
      Offset(_kStaffLeft, _stepToY(-10)),
      Paint()
        ..color = const Color(0xFF333333)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawKeySig(Canvas canvas) {
    for (final entry in keySig.entries) {
      final symbol = entry.value == StaffAccidental.sharp ? '♯' : '♭';
      _drawSymbol(canvas, symbol, _kKeyX, _stepToY(_kTrebleKeySteps[entry.key]!));
      _drawSymbol(canvas, symbol, _kKeyX, _stepToY(_kBassKeySteps[entry.key]!));
    }
  }

  void _drawNotes(Canvas canvas) {
    // (step, keyboard) → (isHovered, needsNatural); hovered overrides active.
    final Map<(int, int), (bool, bool)> noteMap = {};

    if (activeKeys != null) {
      for (int kb = 0; kb < 2; kb++) {
        for (int s = 0; s < 24; s++) {
          if (!activeKeys![kb][s]) continue;
          final info = _resolveNote(kb, s);
          if (info != null) noteMap[(info.step, kb)] = (false, info.needsNatural);
        }
      }
    }

    if (hoveredKeyboard != null && hoveredSemitone != null) {
      final info = _resolveNote(hoveredKeyboard!, hoveredSemitone!);
      if (info != null) {
        noteMap[(info.step, hoveredKeyboard!)] = (true, info.needsNatural);
      }
    }

    if (noteMap.isEmpty) return;

    final notes = noteMap.entries
        .map((e) => (step: e.key.$1, kb: e.key.$2, hovered: e.value.$1, natural: e.value.$2))
        .toList();

    _drawLedgerLines(canvas, notes);
    for (final n in notes) {
      _drawWholeNote(canvas, n.step, n.hovered, n.natural);
    }
  }

  void _drawLedgerLines(
      Canvas canvas, List<({int step, int kb, bool hovered, bool natural})> notes) {
    final Set<int> ledgerSteps = {};
    for (final n in notes) {
      if (n.kb == 0) {
        if (n.step <= 0) ledgerSteps.add(0);
        if (n.step > 10) {
          for (int k = 12; k <= n.step; k += 2) ledgerSteps.add(k);
        }
      } else {
        if (n.step < -10) {
          for (int k = -12; k >= n.step; k -= 2) ledgerSteps.add(k);
        }
      }
    }
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (final step in ledgerSteps) {
      canvas.drawLine(
        Offset(_kNoteX - _kLedgerHalfW, _stepToY(step)),
        Offset(_kNoteX + _kLedgerHalfW, _stepToY(step)),
        paint,
      );
    }
  }

  void _drawWholeNote(Canvas canvas, int step, bool isHovered, bool needsNatural) {
    final y = _stepToY(step);
    final rect = Rect.fromCenter(
      center: Offset(_kNoteX, y),
      width: _kNoteW,
      height: _kNoteH,
    );

    if (isHovered) {
      canvas.drawOval(rect, Paint()
        ..color = const Color(0xFF4A90D9)
        ..style = PaintingStyle.fill);
    } else {
      canvas.drawOval(rect, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill);
      canvas.drawOval(rect, Paint()
        ..color = const Color(0xFF222222)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }

    if (needsNatural) {
      _drawSymbol(
        canvas, '♮',
        _kNoteX - _kNoteW / 2 - 6,
        y,
        color: isHovered ? const Color(0xFF4A90D9) : const Color(0xFF222222),
      );
    }
  }

  void _drawSymbol(Canvas canvas, String symbol, double cx, double cy,
      {double fontSize = 11.0, Color color = const Color(0xFF222222)}) {
    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(fontSize: fontSize, color: color, height: 1.0),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_GrandStaffPainter old) {
    if (old.hoveredKeyboard != hoveredKeyboard ||
        old.hoveredSemitone != hoveredSemitone) return true;
    if (old.keySig.length != keySig.length) return true;
    for (final entry in keySig.entries) {
      if (old.keySig[entry.key] != entry.value) return true;
    }
    if (identical(old.activeKeys, activeKeys)) return false;
    if ((old.activeKeys == null) != (activeKeys == null)) return true;
    for (int kb = 0; kb < 2; kb++) {
      for (int s = 0; s < 24; s++) {
        if (old.activeKeys![kb][s] != activeKeys![kb][s]) return true;
      }
    }
    return false;
  }
}
