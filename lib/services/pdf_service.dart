import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/practice_sheet.dart';

class PdfService {
  Future<void> printOrExport(PracticeSheet sheet) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          11 * PdfPageFormat.inch,
          8.5 * PdfPageFormat.inch,
        ),
        orientation: pw.PageOrientation.landscape,
        margin: pw.EdgeInsets.all(20 * PdfPageFormat.point),
        build: (pw.Context ctx) {
          return pw.Column(
            children: List.generate(3, (row) {
              return pw.Expanded(
                child: pw.Row(
                  children: List.generate(4, (col) {
                    final int mi = row * 4 + col;
                    return pw.Expanded(
                      child: _buildMeasurePdf(mi + 1, sheet.state[mi]),
                    );
                  }),
                ),
              );
            }),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'practice_sheet.pdf',
    );
  }

  pw.Widget _buildMeasurePdf(int measureNumber, List<List<bool>> keyboards) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$measureNumber',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.Expanded(child: _buildKeyboardPdf(keyboards[0])),
          pw.SizedBox(height: 2),
          pw.Expanded(child: _buildKeyboardPdf(keyboards[1])),
        ],
      ),
    );
  }

  pw.Widget _buildKeyboardPdf(List<bool> activeKeys) {
    return pw.CustomPaint(
      painter: (pdfCanvas, size) {
        _drawKeyboardPdf(pdfCanvas, size, activeKeys);
      },
    );
  }

  void _drawKeyboardPdf(
    PdfGraphics canvas,
    PdfPoint size,
    List<bool> activeKeys,
  ) {
    const int whiteKeyCount = 14;
    final double whiteW = size.x / whiteKeyCount;
    final double whiteH = size.y;
    final double blackW = whiteW * 0.6;
    final double blackH = whiteH * 0.62;

    const whiteKeyOrder = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23];
    final blackKeyDefs = [
      (1, 0), (3, 1), (6, 3), (8, 4), (10, 5),
      (13, 7), (15, 8), (18, 10), (20, 11), (22, 12),
    ];

    // White keys
    for (int i = 0; i < whiteKeyOrder.length; i++) {
      final int semi = whiteKeyOrder[i];
      final bool active = activeKeys[semi];
      final double x = i * whiteW;
      final double y = 0;

      canvas.setFillColor(active ? PdfColors.blue400 : PdfColors.white);
      canvas.drawRect(x, y, whiteW, whiteH);
      canvas.fillPath();

      canvas.setStrokeColor(PdfColors.grey500);
      canvas.setLineWidth(0.3);
      canvas.drawRect(x, y, whiteW, whiteH);
      canvas.strokePath();
    }

    // Black keys
    for (final (semi, leftWhiteIdx) in blackKeyDefs) {
      final bool active = activeKeys[semi];
      final double cx = (leftWhiteIdx + 1) * whiteW;
      final double x = cx - blackW / 2;

      canvas.setFillColor(active ? PdfColors.blue400 : PdfColors.white);
      canvas.drawRect(x, 0, blackW, blackH);
      canvas.fillPath();

      // Left, bottom, right border only
      canvas.setStrokeColor(PdfColors.grey900);
      canvas.setLineWidth(1.0);
      canvas.moveTo(x, blackH);
      canvas.lineTo(x, 0);
      canvas.moveTo(x, blackH);
      canvas.lineTo(x + blackW, blackH);
      canvas.lineTo(x + blackW, 0);
      canvas.strokePath();
    }
  }
}
