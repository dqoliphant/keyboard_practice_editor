import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/practice_sheet.dart';

const Color kHighlightColor = Color(0xFF4A90D9);
const Color kHoverColor = Color(0xFFD6E8FA);
const Color kGrayedKeyColor = Color(0xFFCCCCCC);
const Color kBlackKeyColor = Color(0xFF1A1A1A);
const Color kBlackKeyBorderColor = Color(0xFF222222);
const Color kWhiteKeyBorderColor = Color(0xFF000000);
const double kKeyBottomRadius = 3.0;

class PianoKeyboardPainter extends CustomPainter {
  final List<bool> activeKeys;
  final List<int> fingerNumbers;
  final int? hoveredSemitone;
  final Set<int> grayedKeys;
  final bool isForPdf;

  PianoKeyboardPainter({
    required this.activeKeys,
    required this.fingerNumbers,
    this.hoveredSemitone,
    this.grayedKeys = const {},
    this.isForPdf = false,
  });

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
    const double r = kKeyBottomRadius;

    const whiteKeyOrder = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23];
    const blackKeyDefs = [
      (1, 0), (3, 1), (6, 3), (8, 4), (10, 5),
      (13, 7), (15, 8), (18, 10), (20, 11), (22, 12),
    ];

    final fillPaint = Paint()..style = PaintingStyle.fill;

    // White key fills — rounded bottom corners
    for (int i = 0; i < whiteKeyOrder.length; i++) {
      final int semi = whiteKeyOrder[i];
      fillPaint.color = _whiteKeyColor(semi);
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          i * whiteW, 0, (i + 1) * whiteW, whiteH,
          bottomLeft: Radius.circular(r),
          bottomRight: Radius.circular(r),
        ),
        fillPaint,
      );
    }

    // White key borders: one RRect stroke per key so every key's bottom is rounded
    final whiteBorder = Paint()
      ..color = kWhiteKeyBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int i = 0; i < whiteKeyOrder.length; i++) {
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          i * whiteW, 0, (i + 1) * whiteW, whiteH,
          bottomLeft: Radius.circular(r),
          bottomRight: Radius.circular(r),
        ),
        whiteBorder,
      );
    }

    // Black key fills — rounded bottom corners, dark fill when inactive
    final blackBorder = Paint()
      ..color = kBlackKeyBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final (semi, leftWhiteIdx) in blackKeyDefs) {
      final double cx = (leftWhiteIdx + 1) * whiteW;
      final double x = cx - blackW / 2;

      fillPaint.color = _blackKeyColor(semi);
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          x, 0, x + blackW, blackH,
          bottomLeft: Radius.circular(r),
          bottomRight: Radius.circular(r),
        ),
        fillPaint,
      );

      // U-shaped border: left side, rounded bottom, right side — no top edge
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x, blackH - r)
        ..quadraticBezierTo(x, blackH, x + r, blackH)
        ..lineTo(x + blackW - r, blackH)
        ..quadraticBezierTo(x + blackW, blackH, x + blackW, blackH - r)
        ..lineTo(x + blackW, 0);
      canvas.drawPath(path, blackBorder);
    }

    // Finger numbers on top of all keys
    _drawFingerNumbers(canvas, whiteW, whiteH, blackW, blackH);
  }

  void _drawFingerNumbers(Canvas canvas, double whiteW, double whiteH,
      double blackW, double blackH) {
    const whiteKeyOrder = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23];
    const blackKeyDefs = [
      (1, 0), (3, 1), (6, 3), (8, 4), (10, 5),
      (13, 7), (15, 8), (18, 10), (20, 11), (22, 12),
    ];

    final double fontSize = math.min(whiteW * 0.65, 11.0).clamp(7.0, 11.0);

    // White keys: number centered in the visible area below the black keys
    for (int i = 0; i < whiteKeyOrder.length; i++) {
      final semi = whiteKeyOrder[i];
      if (fingerNumbers[semi] > 0) {
        final cx = i * whiteW + whiteW / 2;
        final cy = blackH + (whiteH - blackH) * 0.5;
        _paintNumber(canvas, fingerNumbers[semi], cx, cy, fontSize);
      }
    }

    // Black keys: number centered in the lower half of the key
    final double blackFontSize = (fontSize * 0.85).clamp(6.0, 10.0);
    for (final (semi, leftWhiteIdx) in blackKeyDefs) {
      if (fingerNumbers[semi] > 0) {
        final cx = (leftWhiteIdx + 1) * whiteW;
        final cy = blackH * 0.65;
        _paintNumber(canvas, fingerNumbers[semi], cx, cy, blackFontSize);
      }
    }
  }

  void _paintNumber(Canvas canvas, int n, double cx, double cy, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: '$n',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  bool _isActive(int semi) => activeKeys[semi] || fingerNumbers[semi] > 0;

  Color _whiteKeyColor(int semi) {
    if (_isActive(semi)) return kHighlightColor;
    if (hoveredSemitone == semi) return kHoverColor;
    if (grayedKeys.contains(semi)) return kGrayedKeyColor;
    return Colors.white;
  }

  Color _blackKeyColor(int semi) {
    if (_isActive(semi)) return kHighlightColor;
    if (hoveredSemitone == semi) return kHoverColor;
    if (grayedKeys.contains(semi)) return kGrayedKeyColor;
    return kBlackKeyColor;
  }

  @override
  bool shouldRepaint(PianoKeyboardPainter old) {
    if (old.hoveredSemitone != hoveredSemitone) return true;
    if (old.grayedKeys.length != grayedKeys.length ||
        !grayedKeys.every(old.grayedKeys.contains)) return true;
    for (int i = 0; i < kSemitones; i++) {
      if (old.activeKeys[i] != activeKeys[i]) return true;
      if (old.fingerNumbers[i] != fingerNumbers[i]) return true;
    }
    return false;
  }
}

class PianoKeyboardWidget extends StatefulWidget {
  final List<bool> activeKeys;
  final List<int> fingerNumbers;
  final void Function(int semitone) onKeyTap;
  final void Function(int semitone)? onKeyRightClick;
  final void Function(int? semitone)? onKeyHover;
  final Set<int> grayedKeys;

  const PianoKeyboardWidget({
    super.key,
    required this.activeKeys,
    required this.fingerNumbers,
    required this.onKeyTap,
    this.onKeyRightClick,
    this.onKeyHover,
    this.grayedKeys = const {},
  });

  @override
  State<PianoKeyboardWidget> createState() => _PianoKeyboardWidgetState();
}

class _PianoKeyboardWidgetState extends State<PianoKeyboardWidget> {
  int? _hoveredSemitone;
  double _w = 0;
  double _h = 0;

  static const whiteKeyOrder = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23];
  static const blackKeyDefs = [
    (1, 0), (3, 1), (6, 3), (8, 4), (10, 5),
    (13, 7), (15, 8), (18, 10), (20, 11), (22, 12),
  ];

  int? _semitoneAt(Offset pos) {
    const int whiteKeyCount = 14;
    final double whiteW = _w / whiteKeyCount;
    final double blackW = whiteW * 0.6;
    final double blackH = _h * 0.62;

    if (pos.dy < blackH) {
      for (final (semi, leftWhiteIdx) in blackKeyDefs) {
        final double cx = (leftWhiteIdx + 1) * whiteW;
        final double x = cx - blackW / 2;
        if (pos.dx >= x && pos.dx <= x + blackW) return semi;
      }
    }
    final int whiteIdx = (pos.dx / whiteW).floor().clamp(0, whiteKeyCount - 1);
    return whiteKeyOrder[whiteIdx];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _w = constraints.maxWidth;
        _h = constraints.maxHeight;
        return MouseRegion(
          onHover: (event) {
            final semi = _semitoneAt(event.localPosition);
            if (semi != _hoveredSemitone) {
              setState(() => _hoveredSemitone = semi);
              widget.onKeyHover?.call(semi);
            }
          },
          onExit: (_) {
            if (_hoveredSemitone != null) widget.onKeyHover?.call(null);
            setState(() => _hoveredSemitone = null);
          },
          child: GestureDetector(
            onTapDown: (details) {
              final semi = _semitoneAt(details.localPosition);
              if (semi != null) widget.onKeyTap(semi);
            },
            onSecondaryTapDown: (details) {
              final semi = _semitoneAt(details.localPosition);
              if (semi != null) widget.onKeyRightClick?.call(semi);
            },
            child: CustomPaint(
              size: Size(_w, _h),
              painter: PianoKeyboardPainter(
                activeKeys: widget.activeKeys,
                fingerNumbers: widget.fingerNumbers,
                hoveredSemitone: _hoveredSemitone,
                grayedKeys: widget.grayedKeys,
              ),
            ),
          ),
        );
      },
    );
  }
}
