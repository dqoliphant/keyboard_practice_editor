import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'models/practice_document.dart';
import 'models/practice_sheet.dart';
import 'models/guitar_chord_data.dart';
import 'widgets/grand_staff_widget.dart';
import 'widgets/page_navigator_widget.dart';
import 'services/file_service.dart';
import 'services/pdf_service.dart';

class _MeasureClipboard {
  final List<List<bool>> keyboards;
  final List<List<int>> fingerNumbers;
  final String? chordOverride;
  final GuitarChordData? guitarChordData;

  _MeasureClipboard._({
    required this.keyboards,
    required this.fingerNumbers,
    this.chordOverride,
    this.guitarChordData,
  });

  factory _MeasureClipboard.from(PracticeSheet sheet, int slotIdx) =>
      _MeasureClipboard._(
        keyboards: List.generate(kKeyboardsPerMeasure,
            (kb) => List<bool>.from(sheet.state[slotIdx][kb])),
        fingerNumbers: List.generate(kKeyboardsPerMeasure,
            (kb) => List<int>.from(sheet.fingerNumbers[slotIdx][kb])),
        chordOverride: sheet.chordOverrides[slotIdx],
        guitarChordData: sheet.guitarChords[slotIdx],
      );
}

void main() {
  runApp(const KeyboardPracticeApp());
}

class KeyboardPracticeApp extends StatelessWidget {
  const KeyboardPracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keyboard Practice Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90D9)),
        useMaterial3: true,
      ),
      home: const EditorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  PracticeDocument _document = PracticeDocument();
  final _fileService = FileService();
  final _pdfService = PdfService();
  bool _busy = false;
  bool _showGrandStaff = false;
  int? _hoveredSlot;
  int? _hoveredKeyboard;
  int? _hoveredSemitone;
  _MeasureClipboard? _clipboard;

  void _toggleKey(int slotIdx, int keyboard, int semitone) {
    setState(() => _document.currentPage.toggle(slotIdx, keyboard, semitone));
  }

  void _cycleKeyFinger(int slotIdx, int keyboard, int semitone) {
    setState(() => _document.currentPage.cycleFinger(slotIdx, keyboard, semitone));
  }

  void _copyMeasure(int slotIdx) {
    setState(() => _clipboard = _MeasureClipboard.from(_document.currentPage, slotIdx));
  }

  void _pasteValues(int slotIdx) {
    final clip = _clipboard;
    if (clip == null) return;
    final page = _document.currentPage;
    setState(() {
      if (clip.guitarChordData != null) {
        page.setGuitarChordData(slotIdx, clip.guitarChordData);
      } else {
        page.setGuitarChordData(slotIdx, null);
        for (int kb = 0; kb < kKeyboardsPerMeasure; kb++) {
          for (int semi = 0; semi < kSemitones; semi++) {
            page.state[slotIdx][kb][semi] = clip.keyboards[kb][semi];
            page.fingerNumbers[slotIdx][kb][semi] = clip.fingerNumbers[kb][semi];
          }
        }
        if (clip.chordOverride != null) {
          _document = _document.withCurrentPageUpdated(
            page.withChordOverride(slotIdx, clip.chordOverride!),
          );
        }
      }
    });
  }

  void _pasteNewMeasure(int slotIdx) {
    final clip = _clipboard;
    if (clip == null) return;
    setState(() {
      var newPage = _document.currentPage.withSlotAdded(slotIdx);
      if (clip.guitarChordData != null) {
        newPage.setGuitarChordData(slotIdx, clip.guitarChordData);
      } else {
        for (int kb = 0; kb < kKeyboardsPerMeasure; kb++) {
          for (int semi = 0; semi < kSemitones; semi++) {
            newPage.state[slotIdx][kb][semi] = clip.keyboards[kb][semi];
            newPage.fingerNumbers[slotIdx][kb][semi] = clip.fingerNumbers[kb][semi];
          }
        }
        if (clip.chordOverride != null) {
          newPage = newPage.withChordOverride(slotIdx, clip.chordOverride!);
        }
      }
      _document = _document.withCurrentPageUpdated(newPage);
    });
  }

  void _addMeasure(int slotIdx) {
    setState(() => _document = _document.withCurrentPageUpdated(
          _document.currentPage.withSlotAdded(slotIdx),
        ));
  }

  void _deleteMeasure(int slotIdx) {
    setState(() => _document = _document.withCurrentPageUpdated(
          _document.currentPage.withSlotRemoved(slotIdx),
        ));
  }

  void _goToPage(int index) {
    setState(() => _document = _document.withCurrentPageIndex(index));
  }

  void _insertPageBefore() {
    setState(() => _document =
        _document.withPageInsertedBefore(_document.currentPageIndex));
  }

  void _insertPageAfter() {
    setState(() => _document =
        _document.withPageInsertedAfter(_document.currentPageIndex));
  }

  void _deletePage() {
    setState(() => _document =
        _document.withPageDeleted(_document.currentPageIndex));
  }

  void _updateSongTitle(String title) {
    setState(() => _document = _document.withSongTitle(title));
  }

  void _updateSectionLabel(String label) {
    setState(() => _document = _document.withCurrentPageUpdated(
          _document.currentPage.withSectionLabel(label),
        ));
  }

  void _selectChord(int slotIdx, String chord) {
    setState(() => _document = _document.withCurrentPageUpdated(
          _document.currentPage.withChordOverride(slotIdx, chord),
        ));
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await _fileService.saveDocument(_document);
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final loaded = await _fileService.loadDocument();
      if (loaded != null && mounted) setState(() => _document = loaded);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Load failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    if (_busy || !mounted) return;
    final document = _document;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PrintPreviewDialog(
        document: document,
        pdfService: _pdfService,
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await _pdfService.exportPdf(_document);
      if (path != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('PDF saved to $path')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onKeySigChanged(Map<int, StaffAccidental> keySig) {
    setState(() => _document = _document.withKeySig(keySig));
  }

  // Semitones (0-23) that should be grayed when the key sig is active:
  // - white keys whose note name is altered by the key sig
  // - black keys not covered by the key sig
  Set<int> get _grayedKeys {
    if (!_showGrandStaff) return const {};
    final keySig = _document.keySig;
    const semiToNoteName = {0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6};
    const accidentalNames = {1: (0, 1), 3: (1, 2), 6: (3, 4), 8: (4, 5), 10: (5, 6)};
    final result = <int>{};
    for (int s = 0; s < 24; s++) {
      final semiInOct = s % 12;
      final naturalName = semiToNoteName[semiInOct];
      if (naturalName != null) {
        if (keySig.containsKey(naturalName)) result.add(s);
      } else {
        final accInfo = accidentalNames[semiInOct];
        if (accInfo != null) {
          final (sharpOf, flatOf) = accInfo;
          final covered = keySig[sharpOf] == StaffAccidental.sharp ||
              keySig[flatOf] == StaffAccidental.flat;
          if (!covered) result.add(s);
        }
      }
    }
    return result;
  }

  List<List<bool>>? get _activeStaffKeys {
    if (_hoveredSlot == null) return null;
    final page = _document.currentPage;
    if (!page.occupiedSlots.contains(_hoveredSlot!)) return null;
    if (page.isGuitarSlot(_hoveredSlot!)) {
      return page.guitarChords[_hoveredSlot!]!.toStaffKeys();
    }
    return page.state[_hoveredSlot!];
  }

  void _onMeasureHover(int? slotIdx) {
    setState(() {
      _hoveredSlot = slotIdx;
      if (slotIdx == null || _document.currentPage.isGuitarSlot(slotIdx)) {
        _hoveredKeyboard = null;
        _hoveredSemitone = null;
      }
    });
  }

  void _onKeyHover(int slotIdx, int keyboard, int? semitone) {
    setState(() {
      _hoveredKeyboard = semitone != null ? keyboard : null;
      _hoveredSemitone = semitone;
    });
  }

  // ---------------------------------------------------------------------------
  // Guitar chord actions

  void _convertToGuitar(int slotIdx) {
    setState(() => _document.currentPage.setGuitarChordData(slotIdx, GuitarChordData.blank()));
  }

  void _convertToPiano(int slotIdx) {
    setState(() => _document.currentPage.setGuitarChordData(slotIdx, null));
  }

  void _guitarFretTapped(int slotIdx, int stringIdx, int fretAbsolute) {
    setState(() => _document.currentPage.toggleGuitarFret(slotIdx, stringIdx, fretAbsolute));
  }

  void _guitarStringHeaderTapped(int slotIdx, int stringIdx) {
    setState(() => _document.currentPage.toggleGuitarStringMute(slotIdx, stringIdx));
  }

  void _guitarFingerCycled(int slotIdx, int stringIdx) {
    setState(() => _document.currentPage.cycleGuitarFinger(slotIdx, stringIdx));
  }

  void _guitarChordNameChanged(int slotIdx, String name) {
    setState(() => _document.currentPage.setGuitarChordName(slotIdx, name));
  }

  void _guitarStartFretChanged(int slotIdx, int delta) {
    setState(() => _document.currentPage.shiftGuitarStartFret(slotIdx, delta));
  }

  void _clear() => setState(() => _document = PracticeDocument());

  String get _pageLabel {
    final total = _document.pages.length;
    return total > 1
        ? 'Page ${_document.currentPageIndex + 1} of $total'
        : 'Keyboard Practice Editor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        title: Text(_pageLabel),
        backgroundColor: const Color(0xFF2C5F8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.library_music,
              color: _showGrandStaff ? Colors.white : Colors.white38,
            ),
            tooltip: 'Toggle grand staff',
            onPressed: () => setState(() => _showGrandStaff = !_showGrandStaff),
          ),
          TextButton.icon(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.folder_open, color: Colors.white70),
            label: const Text('Load', style: TextStyle(color: Colors.white70)),
          ),
          TextButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save, color: Colors.white70),
            label: const Text('Save', style: TextStyle(color: Colors.white70)),
          ),
          TextButton.icon(
            onPressed: _busy ? null : _print,
            icon: const Icon(Icons.print, color: Colors.white70),
            label: const Text('Print', style: TextStyle(color: Colors.white70)),
          ),
          TextButton.icon(
            onPressed: _busy ? null : _exportPdf,
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white70),
            label: const Text('Export PDF', style: TextStyle(color: Colors.white70)),
          ),
          TextButton.icon(
            onPressed: _busy ? null : _clear,
            icon: const Icon(Icons.clear_all, color: Colors.white70),
            label: const Text('Clear', style: TextStyle(color: Colors.white70)),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          if (_showGrandStaff)
            GrandStaffWidget(
              activeKeys: _activeStaffKeys,
              hoveredKeyboard: _hoveredKeyboard,
              hoveredSemitone: _hoveredSemitone,
              keySig: _document.keySig,
              onKeySigChanged: _onKeySigChanged,
            ),
          Expanded(
            child: PageNavigatorWidget(
              document: _document,
              onKeyTap: _toggleKey,
              onKeyFingerCycle: _cycleKeyFinger,
              onCopyMeasure: _copyMeasure,
              onPasteValues: _pasteValues,
              onPasteNewMeasure: _pasteNewMeasure,
              hasClipboard: _clipboard != null,
              onAddMeasure: _addMeasure,
              onDeleteMeasure: _deleteMeasure,
              onGoToPage: _goToPage,
              onInsertPageBefore: _insertPageBefore,
              onInsertPageAfter: _insertPageAfter,
              onDeletePage: _document.pages.length > 1 ? _deletePage : null,
              onKeyHover: _showGrandStaff ? _onKeyHover : null,
              onMeasureHover: _showGrandStaff ? _onMeasureHover : null,
              grayedKeys: _grayedKeys,
              onSongTitleChanged: _updateSongTitle,
              onSectionLabelChanged: _updateSectionLabel,
              onChordSelected: _selectChord,
              onConvertToGuitar: _convertToGuitar,
              onConvertToPiano: _convertToPiano,
              onGuitarFretTapped: _guitarFretTapped,
              onGuitarStringHeaderTapped: _guitarStringHeaderTapped,
              onGuitarFingerCycled: _guitarFingerCycled,
              onGuitarChordNameChanged: _guitarChordNameChanged,
              onGuitarStartFretChanged: _guitarStartFretChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PrintPreviewDialog extends StatelessWidget {
  final PracticeDocument document;
  final PdfService pdfService;

  const _PrintPreviewDialog({
    required this.document,
    required this.pdfService,
  });

  static final _letterLandscape = PdfPageFormat(
    11 * PdfPageFormat.inch,
    8.5 * PdfPageFormat.inch,
  );

  @override
  Widget build(BuildContext context) {
    final fileName = document.songTitle.isNotEmpty
        ? '${document.songTitle}.pdf'
        : 'practice_sheet.pdf';

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header bar
          Container(
            color: const Color(0xFF2C5F8A),
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            child: Row(
              children: [
                const Text(
                  'Print Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Preview
          Expanded(
            child: PdfPreview(
              build: (_) => pdfService.buildPdfBytes(document),
              initialPageFormat: _letterLandscape,
              allowPrinting: true,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              pdfFileName: fileName,
            ),
          ),
        ],
      ),
    );
  }
}
