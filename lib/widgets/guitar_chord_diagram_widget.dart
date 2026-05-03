import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/guitar_chord_data.dart';

// Shared highlight color matching the piano keyboard widget
const Color _kHighlight = Color(0xFF4A90D9);
const Color _kHover = Color(0xFFD6E8FA);

// ---------------------------------------------------------------------------
// Layout geometry — shared between painter and hit-tester

class _GuitarLayout {
  static const double _kOxH = 22.0;
  static const double _kLabelH = 13.0;
  static const double _kEdgePad = 5.0;
  static const double _kPosNumW = 20.0;

  final double w, h;
  final int startFret;

  late final double posNumW;
  late final double gridLeft, gridRight, gridW;
  late final double gridTop, gridBottom, gridH;
  late final double stringSpacing, fretH;
  late final double dotRadius;

  _GuitarLayout(this.w, this.h, this.startFret) {
    posNumW = startFret > 1 ? _kPosNumW : 0.0;
    gridLeft = _kEdgePad + posNumW;
    gridRight = w - _kEdgePad;
    gridW = gridRight - gridLeft;
    stringSpacing = gridW / (kGuitarStrings - 1);

    gridTop = _kOxH;
    gridBottom = h - _kLabelH - 2.0;
    gridH = gridBottom - gridTop;
    fretH = gridH / kGuitarFretRows;

    dotRadius = (math.min(stringSpacing, fretH) * 0.38).clamp(6.0, 13.0);
  }

  double stringX(int i) => gridLeft + i * stringSpacing;

  // y at the top of fret row `row` (0 = nut line, kGuitarFretRows = bottom)
  double fretLineY(int row) => gridTop + row * fretH;

  Offset cellCenter(int stringIdx, int fretRow) =>
      Offset(stringX(stringIdx), gridTop + (fretRow - 0.5) * fretH);

  Offset oxCenter(int stringIdx) => Offset(stringX(stringIdx), _kOxH / 2.0);

  // Returns (stringIdx, fretRow) where fretRow==0 is the O/X header zone.
  // Returns null if outside the interactive area.
  (int, int)? hitTest(Offset pos) {
    final si = ((pos.dx - gridLeft) / stringSpacing).round();
    if (si < 0 || si >= kGuitarStrings) return null;

    if (pos.dy < 0) return null;
    if (pos.dy < gridTop) return (si, 0); // O/X zone
    if (pos.dy > gridBottom) return null;

    final fr = ((pos.dy - gridTop) / fretH).floor() + 1;
    if (fr < 1 || fr > kGuitarFretRows) return null;
    return (si, fr);
  }
}

// ---------------------------------------------------------------------------
// Painter

class GuitarChordDiagramPainter extends CustomPainter {
  final GuitarChordData chord;
  final int hovString; // -1 = none
  final int hovFretRow; // -1 = none, 0 = O/X zone, 1..kGuitarFretRows = fret row

  const GuitarChordDiagramPainter({
    required this.chord,
    this.hovString = -1,
    this.hovFretRow = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _GuitarLayout(size.width, size.height, chord.startFret);
    _drawOxMarkers(canvas, layout);
    _drawGrid(canvas, layout);
    _drawBarres(canvas, layout);
    _drawDots(canvas, layout);
    _drawFingerNumbers(canvas, layout);
    _drawStringLabels(canvas, layout);
    _drawHover(canvas, layout);
  }

  void _drawOxMarkers(Canvas canvas, _GuitarLayout l) {
    final circlePaint = Paint()
      ..color = const Color(0xFF444444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final xPaint = Paint()
      ..color = const Color(0xFF444444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const r = 5.0;
    const xSize = 5.0;

    for (int i = 0; i < kGuitarStrings; i++) {
      final c = l.oxCenter(i);
      final fret = chord.frets[i];
      if (fret == 0) {
        canvas.drawCircle(c, r, circlePaint);
      } else if (fret == -1) {
        canvas.drawLine(
            Offset(c.dx - xSize, c.dy - xSize), Offset(c.dx + xSize, c.dy + xSize), xPaint);
        canvas.drawLine(
            Offset(c.dx + xSize, c.dy - xSize), Offset(c.dx - xSize, c.dy + xSize), xPaint);
      }
      // If fret > 0 the dot inside the grid shows the note; no O/X needed.
    }
  }

  void _drawGrid(Canvas canvas, _GuitarLayout l) {
    final linePaint = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 1.0;
    final nutPaint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Top line: nut (thick) if startFret==1, else thin like other fret lines
    final topY = l.gridTop;
    canvas.drawLine(
        Offset(l.gridLeft, topY),
        Offset(l.gridRight, topY),
        chord.startFret == 1 ? nutPaint : linePaint);

    // Remaining fret lines
    for (int row = 1; row <= kGuitarFretRows; row++) {
      final y = l.fretLineY(row);
      canvas.drawLine(Offset(l.gridLeft, y), Offset(l.gridRight, y), linePaint);
    }

    // String lines
    for (int i = 0; i < kGuitarStrings; i++) {
      final x = l.stringX(i);
      canvas.drawLine(Offset(x, l.gridTop), Offset(x, l.gridBottom), linePaint);
    }

    // Position number to the left of grid when startFret > 1
    if (chord.startFret > 1) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${chord.startFret}fr',
          style: const TextStyle(
              fontSize: 9, color: Color(0xFF555555), fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(
            l.gridLeft - tp.width - 3,
            l.gridTop + l.fretH / 2 - tp.height / 2,
          ));
    }
  }

  void _drawBarres(Canvas canvas, _GuitarLayout l) {
    final barrePaint = Paint()
      ..color = _kHighlight
      ..style = PaintingStyle.fill;

    for (final barre in _detectBarres()) {
      final x1 = l.stringX(barre.$1);
      final x2 = l.stringX(barre.$2);
      final cy = l.cellCenter(barre.$1, barre.$3).dy;
      final rect =
          Rect.fromLTRB(x1 - l.dotRadius * 0.5, cy - l.dotRadius, x2 + l.dotRadius * 0.5, cy + l.dotRadius);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(l.dotRadius)), barrePaint);
    }
  }

  // Returns list of (fromStr, toStr, fretRow) for detected barres
  List<(int, int, int)> _detectBarres() {
    final result = <(int, int, int)>[];
    for (int row = 1; row <= kGuitarFretRows; row++) {
      final absF = chord.startFret + row - 1;
      int? start;
      for (int s = 0; s <= kGuitarStrings; s++) {
        final match = s < kGuitarStrings &&
            chord.frets[s] == absF &&
            chord.fingers[s] == 1;
        if (match) {
          start ??= s;
        } else if (start != null) {
          if (s - start >= 2) result.add((start, s - 1, row));
          start = null;
        }
      }
    }
    return result;
  }

  void _drawDots(Canvas canvas, _GuitarLayout l) {
    final activePaint = Paint()
      ..color = _kHighlight
      ..style = PaintingStyle.fill;

    for (int i = 0; i < kGuitarStrings; i++) {
      final f = chord.frets[i];
      if (f < chord.startFret || f >= chord.startFret + kGuitarFretRows) continue;
      final row = f - chord.startFret + 1;
      canvas.drawCircle(l.cellCenter(i, row), l.dotRadius, activePaint);
    }
  }

  void _drawFingerNumbers(Canvas canvas, _GuitarLayout l) {
    for (int i = 0; i < kGuitarStrings; i++) {
      final f = chord.frets[i];
      if (f < chord.startFret || f >= chord.startFret + kGuitarFretRows) continue;
      final finger = chord.fingers[i];
      if (finger <= 0) continue;
      final row = f - chord.startFret + 1;
      final c = l.cellCenter(i, row);
      final tp = TextPainter(
        text: TextSpan(
          text: '$finger',
          style: TextStyle(
            fontSize: (l.dotRadius * 1.1).clamp(7.0, 12.0),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
    }
  }

  void _drawStringLabels(Canvas canvas, _GuitarLayout l) {
    for (int i = 0; i < kGuitarStrings; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: kGuitarStringNames[i],
          style: const TextStyle(
              fontSize: 8, color: Color(0xFF777777), fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(
            l.stringX(i) - tp.width / 2,
            l.gridBottom + 2,
          ));
    }
  }

  void _drawHover(Canvas canvas, _GuitarLayout l) {
    if (hovString < 0) return;

    if (hovFretRow == 0) {
      // Hover over O/X zone
      final c = l.oxCenter(hovString);
      canvas.drawCircle(
          c,
          5.0,
          Paint()
            ..color = _kHover
            ..style = PaintingStyle.fill);
    } else if (hovFretRow >= 1 && hovFretRow <= kGuitarFretRows) {
      final absF = chord.startFret + hovFretRow - 1;
      final alreadyDotted = chord.frets[hovString] == absF;
      if (!alreadyDotted) {
        canvas.drawCircle(
            l.cellCenter(hovString, hovFretRow),
            l.dotRadius,
            Paint()
              ..color = _kHover
              ..style = PaintingStyle.fill);
        canvas.drawCircle(
            l.cellCenter(hovString, hovFretRow),
            l.dotRadius,
            Paint()
              ..color = _kHighlight.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0);
      }
    }
  }

  @override
  bool shouldRepaint(GuitarChordDiagramPainter old) =>
      chord != old.chord || hovString != old.hovString || hovFretRow != old.hovFretRow;
}

// ---------------------------------------------------------------------------
// Widget

class GuitarChordDiagramWidget extends StatefulWidget {
  final int measureNumber;
  final GuitarChordData chord;
  final void Function(int stringIdx, int fretAbsolute) onFretTapped;
  final void Function(int stringIdx) onStringHeaderTapped;
  final void Function(int stringIdx) onFingerCycled;
  final void Function(String name) onChordNameChanged;
  final VoidCallback onCopy;
  final VoidCallback? onPasteValues;
  final VoidCallback onDelete;
  final VoidCallback? onConvertToPiano;
  final void Function(int delta) onStartFretChanged;
  final void Function(int? keyboard, int? semitone)? onNoteHover;

  const GuitarChordDiagramWidget({
    super.key,
    required this.measureNumber,
    required this.chord,
    required this.onFretTapped,
    required this.onStringHeaderTapped,
    required this.onFingerCycled,
    required this.onChordNameChanged,
    required this.onCopy,
    this.onPasteValues,
    required this.onDelete,
    this.onConvertToPiano,
    required this.onStartFretChanged,
    this.onNoteHover,
  });

  @override
  State<GuitarChordDiagramWidget> createState() => _GuitarChordDiagramWidgetState();
}

class _GuitarChordDiagramWidgetState extends State<GuitarChordDiagramWidget> {
  int _hovString = -1;
  int _hovFretRow = -1;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.chord.chordName);
  }

  @override
  void didUpdateWidget(GuitarChordDiagramWidget old) {
    super.didUpdateWidget(old);
    if (widget.chord.chordName != _nameCtrl.text) {
      _nameCtrl.text = widget.chord.chordName;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onHover(Offset localPos, double w, double h) {
    final layout = _GuitarLayout(w, h, widget.chord.startFret);
    final hit = layout.hitTest(localPos);
    setState(() {
      _hovString = hit?.$1 ?? -1;
      _hovFretRow = hit?.$2 ?? -1;
    });
    if (hit != null) {
      final (si, fr) = hit;
      // fretRow==0 is the O/X zone — show the open-string note as preview
      final fretAbsolute = fr == 0 ? 0 : widget.chord.startFret + fr - 1;
      final staff = GuitarChordData.noteToStaff(si, fretAbsolute);
      widget.onNoteHover?.call(staff?.$1, staff?.$2);
    } else {
      widget.onNoteHover?.call(null, null);
    }
  }

  void _onExit() {
    setState(() {
      _hovString = -1;
      _hovFretRow = -1;
    });
    widget.onNoteHover?.call(null, null);
  }

  void _onTapUp(Offset localPos, double w, double h) {
    final layout = _GuitarLayout(w, h, widget.chord.startFret);
    final hit = layout.hitTest(localPos);
    if (hit == null) return;
    final (si, fr) = hit;
    if (fr == 0) {
      widget.onStringHeaderTapped(si);
    } else {
      final absF = widget.chord.startFret + fr - 1;
      widget.onFretTapped(si, absF);
    }
  }

  bool _isActiveDot(int si, int fr) {
    if (fr < 1) return false;
    final absF = widget.chord.startFret + fr - 1;
    return widget.chord.frets[si] == absF;
  }

  void _onSecondaryTapUp(Offset localPos, Offset globalPos, double w, double h) {
    final layout = _GuitarLayout(w, h, widget.chord.startFret);
    final hit = layout.hitTest(localPos);
    if (hit != null && _isActiveDot(hit.$1, hit.$2)) {
      widget.onFingerCycled(hit.$1);
      return;
    }
    _showContextMenu(globalPos);
  }

  void _showContextMenu(Offset globalPos) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          globalPos.dx, globalPos.dy, globalPos.dx, globalPos.dy),
      items: [
        const PopupMenuItem(value: 'copy', child: Text('Copy')),
        if (widget.onPasteValues != null)
          const PopupMenuItem(value: 'paste_values', child: Text('Paste Values')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'fret_up', child: Text('Shift fret up')),
        const PopupMenuItem(value: 'fret_down', child: Text('Shift fret down')),
        const PopupMenuDivider(),
        if (widget.onConvertToPiano != null)
          const PopupMenuItem(value: 'to_piano', child: Text('Convert to Piano')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete', child: Text('Delete measure')),
      ],
    );
    switch (result) {
      case 'copy':
        widget.onCopy();
      case 'paste_values':
        widget.onPasteValues?.call();
      case 'fret_up':
        widget.onStartFretChanged(1);
      case 'fret_down':
        widget.onStartFretChanged(-1);
      case 'to_piano':
        widget.onConvertToPiano?.call();
      case 'delete':
        widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(child: _buildDiagram()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 18.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${widget.measureNumber}',
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF888888), fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                textAlign: TextAlign.center,
                onChanged: widget.onChordNameChanged,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  height: 1.0,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Chord',
                  hintStyle: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBBBBBB),
                    fontWeight: FontWeight.w400,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagram() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return MouseRegion(
          onHover: (e) => _onHover(e.localPosition, w, h),
          onExit: (_) => _onExit(),
          child: GestureDetector(
            onTapUp: (d) => _onTapUp(d.localPosition, w, h),
            onSecondaryTapUp: (d) =>
                _onSecondaryTapUp(d.localPosition, d.globalPosition, w, h),
            child: CustomPaint(
              painter: GuitarChordDiagramPainter(
                chord: widget.chord,
                hovString: _hovString,
                hovFretRow: _hovFretRow,
              ),
              size: Size(w, h),
            ),
          ),
        );
      },
    );
  }
}
