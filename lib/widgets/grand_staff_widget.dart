import 'package:flutter/material.dart';
import '../models/staff_accidental.dart';

export '../models/staff_accidental.dart';

// Layout constants
const double _kStepH = 16.0;
const double _kCenterY = 268.0; // y-coordinate of middle C (diatonic step 0)
const double _kPanelWidth = 296.0;
const double _kPanelHeight = 560.0;
const double _kStaffLeft = 68.0;
const double _kStaffRight = 264.0;
const double _kNoteX = 188.0;
const double _kNoteW = 24.0;
const double _kNoteH = 16.0;
const double _kLedgerHalfW = 20.0;
const double _kKeyX = 92.0; // center-x for key-signature symbols

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

({String major, String minor}) _keyNames(Map<int, StaffAccidental> keySig) {
  if (keySig.isEmpty) return (major: 'C', minor: 'A');
  final allSharp = keySig.values.every((v) => v == StaffAccidental.sharp);
  final allFlat  = keySig.values.every((v) => v == StaffAccidental.flat);
  if (!allSharp && !allFlat) return (major: '?', minor: '?');
  const sharpMajors = ['C', 'G', 'D', 'A', 'E', 'B', 'F♯', 'C♯'];
  const sharpMinors = ['A', 'E', 'B', 'F♯', 'C♯', 'G♯', 'D♯', 'A♯'];
  const flatMajors  = ['C', 'F', 'B♭', 'E♭', 'A♭', 'D♭', 'G♭', 'C♭'];
  const flatMinors  = ['A', 'D', 'G', 'C', 'F', 'B♭', 'E♭', 'A♭'];
  final n = keySig.length.clamp(0, 7);
  if (allSharp) return (major: sharpMajors[n], minor: sharpMinors[n]);
  return (major: flatMajors[n], minor: flatMinors[n]);
}

// ---------------------------------------------------------------------------

class GrandStaffWidget extends StatelessWidget {
  final List<List<bool>>? activeKeys; // [2][24] or null
  final int? hoveredKeyboard;
  final int? hoveredSemitone;
  final Map<int, StaffAccidental> keySig;
  final void Function(Map<int, StaffAccidental>) onKeySigChanged;

  const GrandStaffWidget({
    super.key,
    required this.activeKeys,
    required this.hoveredKeyboard,
    required this.hoveredSemitone,
    required this.keySig,
    required this.onKeySigChanged,
  });

  void _onTapDown(TapDownDetails details) {
    final step = ((_kCenterY - details.localPosition.dy) / _kStepH).round();
    final noteName = step % 7;
    final updated = Map<int, StaffAccidental>.from(keySig);
    final current = updated[noteName];
    if (current == null) {
      updated[noteName] = StaffAccidental.sharp;
    } else if (current == StaffAccidental.sharp) {
      updated[noteName] = StaffAccidental.flat;
    } else {
      updated.remove(noteName);
    }
    onKeySigChanged(updated);
  }

  static const _labelStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: Color(0xFF333333),
    height: 1.2,
  );
  static const _sublabelStyle = TextStyle(
    fontSize: 22,
    fontStyle: FontStyle.italic,
    color: Color(0xFF666666),
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    final names = _keyNames(keySig);
    final staffPanel = Container(
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
                    activeKeys: activeKeys,
                    hoveredKeyboard: hoveredKeyboard,
                    hoveredSemitone: hoveredSemitone,
                    keySig: keySig,
                  ),
                ),
              ),
              Positioned(
                left: 2,
                top: _stepToY(10) - 16,
                child: const IgnorePointer(
                  child: Text(
                    '\u{1D11E}',
                    style: TextStyle(fontSize: 104, height: 1.0, color: Color(0xFF222222)),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                top: _stepToY(-2) - 8,
                child: const IgnorePointer(
                  child: Text(
                    '\u{1D122}',
                    style: TextStyle(fontSize: 72, height: 1.0, color: Color(0xFF222222)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      width: _kPanelWidth,
      color: const Color(0xFFD8D8D8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('${names.major} major', style: _labelStyle),
            const SizedBox(height: 12),
            staffPanel,
            const SizedBox(height: 12),
            Text('${names.minor} minor', style: _sublabelStyle),
            const SizedBox(height: 12),
          ],
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

  // Returns the diatonic step and an optional accidental symbol to display.
  // symbol == '♮' : natural note conflicts with key sig
  // symbol == '♯' / '♭' : accidental not covered by key sig
  // symbol == null : no symbol needed
  // Always returns a position (never null) — accidentals default to sharp spelling.
  ({int step, String? symbol})? _resolveNote(int keyboard, int semitone) {
    final oct = semitone ~/ 12;
    final semiInOct = semitone % 12;

    // Natural note
    final naturalDiatonic = _kSemiToDiatonic[semiInOct];
    if (naturalDiatonic != null) {
      final step = _kKbBaseStep[keyboard] + oct * 7 + naturalDiatonic;
      final symbol = keySig.containsKey(naturalDiatonic) ? '♮' : null;
      return (step: step, symbol: symbol);
    }

    // Accidental note
    final accInfo = _kAccidentalNames[semiInOct];
    if (accInfo != null) {
      final (sharpOf, flatOf) = accInfo;
      // Key sig explains it — display at the natural position, no symbol
      if (keySig[sharpOf] == StaffAccidental.sharp) {
        return (step: _kKbBaseStep[keyboard] + oct * 7 + sharpOf, symbol: null);
      }
      if (keySig[flatOf] == StaffAccidental.flat) {
        return (step: _kKbBaseStep[keyboard] + oct * 7 + flatOf, symbol: null);
      }
      // Not covered: show with ♯ or ♭ depending on which side of the key sig we're on.
      final flatCount = keySig.values.where((v) => v == StaffAccidental.flat).length;
      final sharpCount = keySig.values.where((v) => v == StaffAccidental.sharp).length;
      if (flatCount > sharpCount) {
        return (step: _kKbBaseStep[keyboard] + oct * 7 + flatOf, symbol: '♭');
      }
      return (step: _kKbBaseStep[keyboard] + oct * 7 + sharpOf, symbol: '♯');
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
      ..strokeWidth = 1.6
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
        ..strokeWidth = 3.0
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
    // Key: (step, kb, symbol) — two noteheads at the same step with different
    // accidentals are stored as separate entries.
    // Value: (isActive, isHovered)
    final Map<(int, int, String?), (bool, bool)> noteMap = {};

    if (activeKeys != null) {
      for (int kb = 0; kb < 2; kb++) {
        for (int s = 0; s < 24; s++) {
          if (!activeKeys![kb][s]) continue;
          final info = _resolveNote(kb, s);
          if (info != null) noteMap[(info.step, kb, info.symbol)] = (true, false);
        }
      }
    }

    if (hoveredKeyboard != null && hoveredSemitone != null) {
      final info = _resolveNote(hoveredKeyboard!, hoveredSemitone!);
      if (info != null) {
        final key = (info.step, hoveredKeyboard!, info.symbol);
        final wasActive = noteMap[key]?.$1 ?? false;
        noteMap[key] = (wasActive, true);
      }
    }

    if (noteMap.isEmpty) return;

    // Group by (step, kb) to detect two noteheads at the same staff position.
    final Map<(int, int), List<({String? symbol, bool isActive, bool isHovered})>> byPos = {};
    for (final e in noteMap.entries) {
      byPos.putIfAbsent((e.key.$1, e.key.$2), () => [])
          .add((symbol: e.key.$3, isActive: e.value.$1, isHovered: e.value.$2));
    }
    // Stable sort: null symbol (natural) left, accidentals right.
    for (final group in byPos.values) {
      group.sort((a, b) {
        if (a.symbol == b.symbol) return 0;
        if (a.symbol == null) return -1;
        if (b.symbol == null) return 1;
        return a.symbol!.compareTo(b.symbol!);
      });
    }

    _drawLedgerLines(canvas, {
      for (final e in byPos.entries) e.key: e.value.length,
    });

    for (final entry in byPos.entries) {
      final step = entry.key.$1;
      final group = entry.value;
      if (group.length == 1) {
        final n = group[0];
        _drawWholeNote(canvas, step, _kNoteX, n.isActive, n.isHovered, n.symbol);
      } else {
        // Two noteheads side by side; centres separated by noteWidth + 2 px gap.
        final x1 = _kNoteX - (_kNoteW / 2 + 1);
        final x2 = _kNoteX + (_kNoteW / 2 + 1);
        // Any accidental on the right notehead must clear the left notehead,
        // so override its symbol x to sit left of x1's left edge.
        final symXForRight = x1 - _kNoteW / 2 - 6;
        _drawWholeNote(canvas, step, x1, group[0].isActive, group[0].isHovered, group[0].symbol);
        _drawWholeNote(canvas, step, x2, group[1].isActive, group[1].isHovered, group[1].symbol,
            symbolX: symXForRight);
      }
    }
  }

  // stepKbCounts: (step, kb) → number of noteheads at that position.
  void _drawLedgerLines(Canvas canvas, Map<(int, int), int> stepKbCounts) {
    // Track the required half-width per ledger step (wider for double noteheads).
    final Map<int, double> ledgerHw = {};
    void addLedger(int step, int count) {
      final hw = count > 1 ? _kLedgerHalfW + 3.0 : _kLedgerHalfW.toDouble();
      ledgerHw.update(step, (v) => v > hw ? v : hw, ifAbsent: () => hw);
    }
    for (final e in stepKbCounts.entries) {
      final step = e.key.$1;
      final kb = e.key.$2;
      final count = e.value;
      if (kb == 0) {
        if (step <= 0) addLedger(0, count);
        if (step > 10) {
          for (int k = 12; k <= step; k += 2) addLedger(k, count);
        }
      } else {
        if (step < -10) {
          for (int k = -12; k >= step; k -= 2) addLedger(k, count);
        }
      }
    }
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (final e in ledgerHw.entries) {
      canvas.drawLine(
        Offset(_kNoteX - e.value, _stepToY(e.key)),
        Offset(_kNoteX + e.value, _stepToY(e.key)),
        paint,
      );
    }
  }

  void _drawWholeNote(Canvas canvas, int step, double x,
      bool isActive, bool isHovered, String? symbol, {double? symbolX}) {
    final y = _stepToY(step);
    final rect = Rect.fromCenter(center: Offset(x, y), width: _kNoteW, height: _kNoteH);

    if (isActive && !isHovered) {
      canvas.drawOval(rect, Paint()
        ..color = const Color(0xFF222222)
        ..style = PaintingStyle.fill);
    } else if (isActive && isHovered) {
      canvas.drawOval(rect, Paint()
        ..color = const Color(0xFF4A90D9)
        ..style = PaintingStyle.fill);
      canvas.drawOval(rect, Paint()
        ..color = const Color(0xFF222222)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0);
    } else {
      canvas.drawOval(rect, Paint()
        ..color = const Color(0xFF4A90D9)
        ..style = PaintingStyle.fill);
    }

    if (symbol != null) {
      _drawSymbol(canvas, symbol, symbolX ?? x - _kNoteW / 2 - 6, y,
          color: isActive ? const Color(0xFF222222) : const Color(0xFF4A90D9));
    }
  }

  void _drawSymbol(Canvas canvas, String symbol, double cx, double cy,
      {double fontSize = 22.0, Color color = const Color(0xFF222222)}) {
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
