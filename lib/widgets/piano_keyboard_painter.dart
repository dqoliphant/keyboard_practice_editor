import 'package:flutter/material.dart';
import '../models/practice_sheet.dart';

const Color kHighlightColor = Color(0xFF4A90D9);
const Color kBlackKeyBorderColor = Color(0xFF222222);
const Color kWhiteKeyBorderColor = Color(0xFF888888);

class PianoKeyboardPainter extends CustomPainter {
  final List<bool> activeKeys; // length kSemitones
  final bool isForPdf;

  PianoKeyboardPainter({required this.activeKeys, this.isForPdf = false});

  @override
  void paint(Canvas canvas, Size size) {
    _drawKeyboard(canvas, size);
  }

  void _drawKeyboard(Canvas canvas, Size size) {
    const int whiteKeyCount = 14;
    final double whiteW = size.width / whiteKeyCount;
    final double whiteH = size.height;
    final double blackW = whiteW * 0.6;
    final double blackH = whiteH * 0.62;

    // White key x positions (semitone -> x offset in units of whiteW)
    // C D E F G A B | C D E F G A B
    // 0 2 4 5 7 9 11 | 12 14 16 17 19 21 23
    const whiteKeyOrder = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23];

    // Draw white keys first
    for (int i = 0; i < whiteKeyOrder.length; i++) {
      final int semi = whiteKeyOrder[i];
      final bool active = activeKeys[semi];
      final Rect rect = Rect.fromLTWH(i * whiteW, 0, whiteW, whiteH);

      final fillPaint = Paint()
        ..color = active ? kHighlightColor : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);

      final borderPaint = Paint()
        ..color = kWhiteKeyBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawRect(rect, borderPaint);
    }

    // Black key positions: offset from left edge of preceding white key
    // Pattern in one octave (7 white keys):
    // C#(1) between C(0) and D(2): after white index 0
    // D#(3) between D(2) and E(4): after white index 1
    // F#(6) between F(5) and G(7): after white index 3
    // G#(8) between G(7) and A(9): after white index 4
    // A#(10) between A(9) and B(11): after white index 5
    // Then repeat for octave 2 (add 7 to white index, 12 to semitone)
    final blackKeyDefs = [
      // (semitone, whiteIndexLeft) — black key sits between whiteIndexLeft and whiteIndexLeft+1
      (1, 0),
      (3, 1),
      (6, 3),
      (8, 4),
      (10, 5),
      (13, 7),
      (15, 8),
      (18, 10),
      (20, 11),
      (22, 12),
    ];

    for (final (semi, leftWhiteIdx) in blackKeyDefs) {
      final bool active = activeKeys[semi];
      // Center black key between left and right white keys
      final double cx = (leftWhiteIdx + 1) * whiteW;
      final double x = cx - blackW / 2;

      final fillPaint = Paint()
        ..color = active ? kHighlightColor : Colors.white
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(x, 0, blackW, blackH);
      canvas.drawRect(rect, fillPaint);

      // Border: left, bottom, right only (no top border)
      final borderPaint = Paint()
        ..color = kBlackKeyBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x, blackH)
        ..lineTo(x + blackW, blackH)
        ..lineTo(x + blackW, 0);
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(PianoKeyboardPainter old) =>
      old.activeKeys != activeKeys ||
      List.generate(kSemitones, (i) => old.activeKeys[i] != activeKeys[i])
          .any((v) => v);
}

class PianoKeyboardWidget extends StatelessWidget {
  final List<bool> activeKeys;
  final void Function(int semitone) onKeyTap;

  const PianoKeyboardWidget({
    super.key,
    required this.activeKeys,
    required this.onKeyTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        return GestureDetector(
          onTapDown: (details) => _handleTap(details.localPosition, w, h),
          child: CustomPaint(
            size: Size(w, h),
            painter: PianoKeyboardPainter(activeKeys: activeKeys),
          ),
        );
      },
    );
  }

  void _handleTap(Offset pos, double width, double height) {
    const int whiteKeyCount = 14;
    final double whiteW = width / whiteKeyCount;
    final double blackW = whiteW * 0.6;
    final double blackH = height * 0.62;

    const whiteKeyOrder = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23];
    final blackKeyDefs = [
      (1, 0), (3, 1), (6, 3), (8, 4), (10, 5),
      (13, 7), (15, 8), (18, 10), (20, 11), (22, 12),
    ];

    // Check black keys first (they render on top)
    if (pos.dy < blackH) {
      for (final (semi, leftWhiteIdx) in blackKeyDefs) {
        final double cx = (leftWhiteIdx + 1) * whiteW;
        final double x = cx - blackW / 2;
        if (pos.dx >= x && pos.dx <= x + blackW) {
          onKeyTap(semi);
          return;
        }
      }
    }

    // White key hit
    final int whiteIdx = (pos.dx / whiteW).floor().clamp(0, whiteKeyCount - 1);
    onKeyTap(whiteKeyOrder[whiteIdx]);
  }
}
