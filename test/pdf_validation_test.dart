import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_practice_editor/models/practice_document.dart';
import 'package:keyboard_practice_editor/models/practice_sheet.dart';
import 'package:keyboard_practice_editor/services/pdf_service.dart';

void main() {
  test('generates PDF and saves to disk for visual validation', () async {
    // Build a 2-page document with realistic content
    var doc = PracticeDocument();
    doc = doc.withSongTitle('Test Song');

    // Page 1 — Verse: C major chord in slot 0, Am in slot 1, F in slot 5
    var page1 = doc.currentPage.withSectionLabel('Verse');

    // C major: C(0), E(4), G(7)
    page1.state[0][0][0] = true;  // C
    page1.state[0][0][4] = true;  // E
    page1.state[0][0][7] = true;  // G
    page1 = page1.withSlotAdded(1);
    // Am: A(9), C(0), E(4)
    page1.state[1][0][9] = true;
    page1.state[1][0][0] = true;
    page1.state[1][0][4] = true;
    page1 = page1.withSlotAdded(5);
    // Fmaj7: F(5), A(9), C(0), E(4)
    page1.state[5][1][5] = true;
    page1.state[5][1][9] = true;
    page1.state[5][1][0] = true;
    page1.state[5][1][4] = true;

    doc = doc.withCurrentPageUpdated(page1);

    // Page 2 — Chorus: G7 in slot 0
    doc = doc.withPageInsertedAfter(0);
    var page2 = doc.currentPage.withSectionLabel('Chorus');
    // G7: G(7), B(11), D(2), F(5)
    page2.state[0][0][7] = true;
    page2.state[0][0][11] = true;
    page2.state[0][0][2] = true;
    page2.state[0][0][5] = true;
    doc = doc.withCurrentPageUpdated(page2);

    final bytes = await PdfService().buildPdfBytes(doc);
    expect(bytes.length, greaterThan(1000));

    final outPath = '${Directory.current.path}/test_output.pdf';
    await File(outPath).writeAsBytes(bytes);
    print('PDF saved to: $outPath');
  });
}
