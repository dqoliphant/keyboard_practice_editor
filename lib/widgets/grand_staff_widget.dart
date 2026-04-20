import 'package:flutter/material.dart';

// Layout constants — shared between widget and painter.
const double _kStepH = 8.0;
const double _kCenterY = 134.0; // y-coordinate of middle C (step 0)
const double _kPanelWidth = 148.0;
const double _kPanelHeight = 280.0;
const double _kStaffLeft = 34.0;
const double _kStaffRight = 132.0;
const double _kNoteX = 94.0;
const double _kNoteW = 12.0;
const double _kNoteH = 8.0;
const double _kLedgerHalfW = 10.0;

double _stepToY(int step) => _kCenterY - step * _kStepH;

// Keyboard pitch assignments:
//   Keyboard 0 (treble): semitone 0 = C4, semitone 23 = B5
//   Keyboard 1 (bass):   semitone 0 = C2, semitone 23 = B3
// C4 is 0 diatonic steps from C4; C2 is -14 diatonic steps from C4.
const List<int> _kKbBaseStep = [0, -14];

// Natural semitones within an octave → diatonic offset (0=C, 1=D, …, 6=B).
const Map<int, int> _kSemiToDiatonic = {
  0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6,
};

int? _toStep(int keyboard, int semitone) {
  final oct = semitone ~/ 12;
  final d = _kSemiToDiatonic[semitone % 12];
  if (d == null) return null;
  return _kKbBaseStep[keyboard] + oct * 7 + d;
}

// ---------------------------------------------------------------------------

class GrandStaffWidget extends StatelessWidget {
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
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GrandStaffPainter(
                    activeKeys: activeKeys,
                    hoveredKeyboard: hoveredKeyboard,
                    hoveredSemitone: hoveredSemitone,
                  ),
                ),
              ),
              // Treble clef — positioned so the symbol spans the treble staff
              Positioned(
                left: 1,
                top: _stepToY(10) - 8,
                child: const Text(
                  '\u{1D11E}', // 𝄞 MUSICAL SYMBOL G CLEF
                  style: TextStyle(
                    fontSize: 52,
                    height: 1.0,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
              // Bass clef — positioned so the dots straddle the F3 line
              Positioned(
                left: 3,
                top: _stepToY(-2) - 4,
                child: const Text(
                  '\u{1D122}', // 𝄢 MUSICAL SYMBOL F CLEF
                  style: TextStyle(
                    fontSize: 36,
                    height: 1.0,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
            ],
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

  static const List<int> _trebleLines = [2, 4, 6, 8, 10];
  static const List<int> _bassLines = [-2, -4, -6, -8, -10];

  const _GrandStaffPainter({
    required this.activeKeys,
    required this.hoveredKeyboard,
    required this.hoveredSemitone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawStaffLines(canvas);
    _drawBarline(canvas);
    _drawNotes(canvas);
  }

  void _drawStaffLines(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (final step in _trebleLines) {
      final y = _stepToY(step);
      canvas.drawLine(Offset(_kStaffLeft, y), Offset(_kStaffRight, y), paint);
    }
    for (final step in _bassLines) {
      final y = _stepToY(step);
      canvas.drawLine(Offset(_kStaffLeft, y), Offset(_kStaffRight, y), paint);
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

  void _drawNotes(Canvas canvas) {
    // (step, keyboard) → isHovered; hovered overrides active for same pitch.
    final Map<(int, int), bool> noteMap = {};

    if (activeKeys != null) {
      for (int kb = 0; kb < 2; kb++) {
        for (int s = 0; s < 24; s++) {
          if (activeKeys![kb][s]) {
            final step = _toStep(kb, s);
            if (step != null) noteMap[(step, kb)] = false;
          }
        }
      }
    }

    if (hoveredKeyboard != null && hoveredSemitone != null) {
      final step = _toStep(hoveredKeyboard!, hoveredSemitone!);
      if (step != null) noteMap[(step, hoveredKeyboard!)] = true;
    }

    if (noteMap.isEmpty) return;

    final notes = noteMap.entries
        .map((e) => (step: e.key.$1, kb: e.key.$2, hovered: e.value))
        .toList();

    _drawLedgerLines(canvas, notes);

    for (final n in notes) {
      _drawWholeNote(canvas, n.step, n.hovered);
    }
  }

  void _drawLedgerLines(
      Canvas canvas, List<({int step, int kb, bool hovered})> notes) {
    final Set<int> ledgerSteps = {};

    for (final n in notes) {
      if (n.kb == 0) {
        // Treble: middle C ledger if note is at or below it
        if (n.step <= 0) ledgerSteps.add(0);
        // Treble: ledger lines above the staff
        if (n.step > 10) {
          for (int k = 12; k <= n.step; k += 2) ledgerSteps.add(k);
        }
      } else {
        // Bass: ledger lines below the staff
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
      final y = _stepToY(step);
      canvas.drawLine(
        Offset(_kNoteX - _kLedgerHalfW, y),
        Offset(_kNoteX + _kLedgerHalfW, y),
        paint,
      );
    }
  }

  void _drawWholeNote(Canvas canvas, int step, bool isHovered) {
    final rect = Rect.fromCenter(
      center: Offset(_kNoteX, _stepToY(step)),
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
  }

  @override
  bool shouldRepaint(_GrandStaffPainter old) {
    if (old.hoveredKeyboard != hoveredKeyboard ||
        old.hoveredSemitone != hoveredSemitone) return true;
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
