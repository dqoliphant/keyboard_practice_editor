import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/practice_document.dart';
import '../models/practice_sheet.dart';

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
                        padding: const pw.EdgeInsets.all(3),
                        child: sheet.occupiedSlots.contains(slotIdx)
                            ? _buildMeasure(
                                sheet.measureNumberForSlot(slotIdx),
                                sheet.state[slotIdx],
                                sheet.activeChordForSlot(slotIdx),
                              )
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

  pw.Widget _buildMeasure(int measureNumber, List<List<bool>> keyboards, String? chord) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 0.5),
      ),
      child: pw.Column(
        children: [
          // Header: measure number left, chord centred
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            child: pw.Row(
              children: [
                pw.Text(
                  '$measureNumber',
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
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
          pw.Expanded(child: _buildKeyboard(keyboards[0])),
          pw.SizedBox(height: 2),
          pw.Expanded(child: _buildKeyboard(keyboards[1])),
          pw.SizedBox(height: 2),
        ],
      ),
    );
  }

  // Keyboard rendered as widgets so layout constraints are respected.
  pw.Widget _buildKeyboard(List<bool> activeKeys) {
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

      return pw.Stack(
        children: [
          // White keys — full height, tiled across full width
          pw.Positioned.fill(
            child: pw.Row(
              children: List.generate(14, (i) {
                final bool active = activeKeys[whiteKeyOrder[i]];
                return pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      color: active ? PdfColors.blue400 : PdfColors.white,
                      border: pw.Border.all(color: PdfColors.black, width: 0.3),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Black keys — sit at the top, shorter than white keys
          for (final (semi, leftWhite) in blackKeyDefs)
            pw.Positioned(
              left: (leftWhite + 1) * keyW - blackW / 2,
              top: 0,
              child: pw.SizedBox(
                width: blackW,
                height: blackH,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: activeKeys[semi] ? PdfColors.blue400 : PdfColors.black,
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.grey900, width: 0.5),
                      bottom: pw.BorderSide(color: PdfColors.grey900, width: 0.5),
                      right: pw.BorderSide(color: PdfColors.grey900, width: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
