import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/practice_document.dart';
import '../models/practice_sheet.dart';
import '../models/guitar_chord_data.dart';

class PdfService {
  Future<Uint8List> buildPdfBytes(PracticeDocument document) async {
    final doc = pw.Document();

    for (final sheet in document.pages) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            11 * PdfPageFormat.inch,
            8.5 * PdfPageFormat.inch,
          ),
          orientation: pw.PageOrientation.landscape,
          margin: pw.EdgeInsets.all(20 * PdfPageFormat.point),
          build: (pw.Context ctx) => _buildPage(document.songTitle, sheet),
        ),
      );
    }

    return doc.save();
  }

  Future<void> print(PracticeDocument document) async {
    final bytes = await buildPdfBytes(document);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: _pdfName(document),
    );
  }

  Future<String?> exportPdf(PracticeDocument document) async {
    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export PDF',
      fileName: _pdfName(document),
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (path == null) return null;
    final bytes = await buildPdfBytes(document);
    await File(path).writeAsBytes(bytes);
    return path;
  }

  String _pdfName(PracticeDocument document) =>
      document.songTitle.isNotEmpty ? '${document.songTitle}.pdf' : 'practice_sheet.pdf';

  // -------------------------------------------------------------------------

  pw.Widget _buildPage(String songTitle, PracticeSheet sheet) {
    return pw.Column(
      children: [
        _buildPageHeader(songTitle, sheet.sectionLabel),
        pw.SizedBox(height: 4),
        pw.Expanded(
          child: pw.Column(
            children: List.generate(3, (row) {
              return pw.Expanded(
                child: pw.Row(
                  children: List.generate(4, (col) {
                    final slotIdx = row * 4 + col;
                    return pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: sheet.occupiedSlots.contains(slotIdx)
                            ? (sheet.isGuitarSlot(slotIdx)
                                ? _buildGuitarMeasure(
                                    sheet.measureNumberForSlot(slotIdx),
                                    sheet.guitarChords[slotIdx]!,
                                  )
                                : _buildMeasure(
                                    sheet.measureNumberForSlot(slotIdx),
                                    sheet.state[slotIdx],
                                    sheet.activeChordForSlot(slotIdx),
                                    sheet.fingerNumbers[slotIdx],
                                  ))
                            : pw.SizedBox(),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPageHeader(String songTitle, String sectionLabel) {
    final hasTitle = songTitle.isNotEmpty;
    final hasSection = sectionLabel.isNotEmpty;
    if (!hasTitle && !hasSection) return pw.SizedBox(height: 24);

    return pw.SizedBox(
      height: 40,
      child: pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (hasTitle)
              pw.Text(
                songTitle,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            if (hasTitle && hasSection) pw.SizedBox(height: 3),
            if (hasSection)
              pw.Text(
                sectionLabel,
                style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildMeasure(int measureNumber, List<List<bool>> keyboards, String? chord, List<List<int>> fingerNumbers) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey400,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            child: pw.Row(
              children: [
                pw.Text(
                  '$measureNumber',
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
                pw.Expanded(
                  child: pw.Text(
                    chord ?? '',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(width: 8),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(3, 3, 3, 3),
              child: _buildKeyboard(keyboards[0], fingerNumbers[0]),
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(3, 0, 3, 3),
              child: _buildKeyboard(keyboards[1], fingerNumbers[1]),
            ),
          ),
        ],
      ),
    );
  }

  // Keyboard rendered as widgets so layout constraints are respected.
  pw.Widget _buildKeyboard(List<bool> activeKeys, List<int> fingerNumbers) {
    const whiteKeyOrder = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23];
    const blackKeyDefs = [
      (1, 0), (3, 1), (6, 3), (8, 4), (10, 5),
      (13, 7), (15, 8), (18, 10), (20, 11), (22, 12),
    ];

    return pw.LayoutBuilder(builder: (context, constraints) {
      final double w = constraints?.maxWidth ?? 100;
      final double h = constraints?.maxHeight ?? 40;
      final double keyW = w / 14;
      final double blackW = keyW * 0.6;
      final double blackH = h * 0.62;
      const double r = 2.0;
      final double fontSize = (keyW * 0.55).clamp(4.0, 8.0);

      bool isActive(int semi) => activeKeys[semi] || fingerNumbers[semi] > 0;

      return pw.Stack(
        children: [
          // White keys — full height; borders drawn per-side to avoid doubling
          pw.Positioned.fill(
            child: pw.Container(
              child: pw.Row(
                children: List.generate(14, (i) {
                  final semi = whiteKeyOrder[i];
                  return pw.Expanded(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: isActive(semi) ? PdfColors.blue400 : PdfColors.white,
                        borderRadius: pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(r),
                          bottomRight: pw.Radius.circular(r),
                        ),
                        border: pw.Border.all(color: PdfColors.black, width: 0.3),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Black keys — shorter, rounded bottom, dark when inactive
          for (final (semi, leftWhite) in blackKeyDefs)
            pw.Positioned(
              left: (leftWhite + 1) * keyW - blackW / 2,
              top: 0,
              child: pw.SizedBox(
                width: blackW,
                height: blackH,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: isActive(semi) ? PdfColors.blue400 : PdfColors.black,
                    borderRadius: pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(r),
                      bottomRight: pw.Radius.circular(r),
                    ),
                    border: pw.Border.all(color: PdfColors.grey900, width: 0.5),
                  ),
                ),
              ),
            ),
          // Finger numbers on white keys
          for (int i = 0; i < 14; i++)
            if (fingerNumbers[whiteKeyOrder[i]] > 0)
              pw.Positioned(
                left: i * keyW,
                bottom: (h - blackH) * 0.1,
                child: pw.SizedBox(
                  width: keyW,
                  child: pw.Text(
                    '${fingerNumbers[whiteKeyOrder[i]]}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: fontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
          // Finger numbers on black keys
          for (final (semi, leftWhite) in blackKeyDefs)
            if (fingerNumbers[semi] > 0)
              pw.Positioned(
                left: (leftWhite + 1) * keyW - blackW / 2,
                top: blackH * 0.45,
                child: pw.SizedBox(
                  width: blackW,
                  child: pw.Text(
                    '${fingerNumbers[semi]}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: fontSize * 0.85,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Guitar chord diagram rendering

  pw.Widget _buildGuitarMeasure(int measureNumber, GuitarChordData chord) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey400,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            child: pw.Row(
              children: [
                pw.Text(
                  '$measureNumber',
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
                pw.Expanded(
                  child: pw.Text(
                    chord.chordName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(width: 8),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(3, 3, 3, 3),
              child: _buildGuitarChordDiagram(chord),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGuitarChordDiagram(GuitarChordData chord) {
    return pw.LayoutBuilder(builder: (context, constraints) {
      final double w = constraints?.maxWidth ?? 80;
      final double h = constraints?.maxHeight ?? 80;

      const double oxH = 16.0;
      const double labelH = 10.0;
      const double edgePad = 4.0;
      final double posNumW = chord.startFret > 1 ? 14.0 : 0.0;

      final double gridLeft = edgePad + posNumW;
      final double gridRight = w - edgePad;
      final double gridW = gridRight - gridLeft;
      final double stringSpacing = gridW / (kGuitarStrings - 1);

      final double gridTop = oxH;
      final double gridBottom = h - labelH - 1;
      final double gridH = gridBottom - gridTop;
      final double fretH = gridH / kGuitarFretRows;

      final double dotR = (math.min(stringSpacing, fretH) * 0.36).clamp(3.0, 8.0);
      final double fontSize = dotR.clamp(4.0, 7.0);

      double sx(int i) => gridLeft + i * stringSpacing;
      // y from top of the pw.Stack (pdf y increases downward in pw.Positioned)
      double cellTopY(int si, int fr) => gridTop + (fr - 0.5) * fretH - dotR;

      bool hasDot(int si) {
        final f = chord.frets[si];
        return f >= chord.startFret && f < chord.startFret + kGuitarFretRows;
      }

      int dotRow(int si) => chord.frets[si] - chord.startFret + 1;

      // Barre detection
      final barres = <(int, int, int)>[];
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
            if (s - start >= 2) barres.add((start, s - 1, row));
            start = null;
          }
        }
      }

      return pw.Stack(
        children: [
          // ── O/X markers ──────────────────────────────────────────────────
          for (int i = 0; i < kGuitarStrings; i++)
            if (chord.frets[i] == 0)
              pw.Positioned(
                left: sx(i) - 4,
                top: oxH / 2 - 4,
                child: pw.SizedBox(
                  width: 8,
                  height: 8,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.8),
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                ),
              )
            else if (chord.frets[i] == -1)
              pw.Positioned(
                left: sx(i) - 4,
                top: oxH / 2 - 4,
                child: pw.SizedBox(
                  width: 8,
                  height: 8,
                  child: pw.Center(
                    child: pw.Text('x',
                        style: pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                  ),
                ),
              ),

          // ── Nut (thick top border when open position) ────────────────────
          if (chord.startFret == 1)
            pw.Positioned(
              left: gridLeft,
              top: gridTop,
              child: pw.SizedBox(
                width: gridW,
                height: 3.5,
                child: pw.Container(color: PdfColors.black),
              ),
            ),

          // ── String lines (thin vertical) ─────────────────────────────────
          for (int i = 0; i < kGuitarStrings; i++)
            pw.Positioned(
              left: sx(i) - 0.3,
              top: gridTop + (chord.startFret == 1 ? 3.5 : 0),
              child: pw.SizedBox(
                width: 0.6,
                height: gridH - (chord.startFret == 1 ? 3.5 : 0),
                child: pw.Container(color: PdfColors.black),
              ),
            ),

          // ── Fret lines (horizontal) ───────────────────────────────────────
          for (int row = 0; row <= kGuitarFretRows; row++)
            if (!(chord.startFret == 1 && row == 0))  // skip nut row (drawn as thick bar above)
              pw.Positioned(
                left: gridLeft,
                top: gridTop + row * fretH - (row == 0 ? 0 : 0),
                child: pw.SizedBox(
                  width: gridW,
                  height: 0.6,
                  child: pw.Container(color: PdfColors.black),
                ),
              ),

          // ── Position number ───────────────────────────────────────────────
          if (chord.startFret > 1)
            pw.Positioned(
              left: 0,
              top: gridTop + fretH * 0.5 - 4,
              child: pw.Text(
                '${chord.startFret}fr',
                style: pw.TextStyle(fontSize: 5, color: PdfColors.grey700),
              ),
            ),

          // ── Barres ────────────────────────────────────────────────────────
          for (final (fs, ts, fr) in barres)
            pw.Positioned(
              left: sx(fs) - dotR * 0.5,
              top: gridTop + (fr - 0.5) * fretH - dotR,
              child: pw.SizedBox(
                width: sx(ts) - sx(fs) + dotR,
                height: dotR * 2,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue400,
                    borderRadius: pw.BorderRadius.circular(dotR),
                  ),
                ),
              ),
            ),

          // ── Dots ──────────────────────────────────────────────────────────
          for (int i = 0; i < kGuitarStrings; i++)
            if (hasDot(i))
              pw.Positioned(
                left: sx(i) - dotR,
                top: cellTopY(i, dotRow(i)),
                child: pw.SizedBox(
                  width: dotR * 2,
                  height: dotR * 2,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue400,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                ),
              ),

          // ── Finger numbers ────────────────────────────────────────────────
          for (int i = 0; i < kGuitarStrings; i++)
            if (hasDot(i) && chord.fingers[i] > 0)
              pw.Positioned(
                left: sx(i) - dotR,
                top: cellTopY(i, dotRow(i)),
                child: pw.SizedBox(
                  width: dotR * 2,
                  height: dotR * 2,
                  child: pw.Center(
                    child: pw.Text(
                      '${chord.fingers[i]}',
                      style: pw.TextStyle(
                        fontSize: fontSize,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

          // ── String labels ─────────────────────────────────────────────────
          for (int i = 0; i < kGuitarStrings; i++)
            pw.Positioned(
              left: sx(i) - 4,
              top: h - labelH,
              child: pw.SizedBox(
                width: 8,
                child: pw.Text(
                  kGuitarStringNames[i],
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700),
                ),
              ),
            ),
        ],
      );
    });
  }
}
