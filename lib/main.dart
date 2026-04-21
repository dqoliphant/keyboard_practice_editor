import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'models/practice_document.dart';
import 'widgets/grand_staff_widget.dart';
import 'widgets/page_navigator_widget.dart';
import 'services/file_service.dart';
import 'services/pdf_service.dart';

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
  Map<int, StaffAccidental> _keySig = const {};
  int? _hoveredSlot;
  int? _hoveredKeyboard;
  int? _hoveredSemitone;

  void _toggleKey(int slotIdx, int keyboard, int semitone) {
    setState(() => _document.currentPage.toggle(slotIdx, keyboard, semitone));
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
    setState(() => _keySig = keySig);
  }

  // Semitones (0-23) that should be grayed when the key sig is active:
  // - white keys whose note name is altered by the key sig
  // - black keys not covered by the key sig
  Set<int> get _grayedKeys {
    if (!_showGrandStaff) return const {};
    const semiToNoteName = {0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6};
    const accidentalNames = {1: (0, 1), 3: (1, 2), 6: (3, 4), 8: (4, 5), 10: (5, 6)};
    final result = <int>{};
    for (int s = 0; s < 24; s++) {
      final semiInOct = s % 12;
      final naturalName = semiToNoteName[semiInOct];
      if (naturalName != null) {
        if (_keySig.containsKey(naturalName)) result.add(s);
      } else {
        final accInfo = accidentalNames[semiInOct];
        if (accInfo != null) {
          final (sharpOf, flatOf) = accInfo;
          final covered = _keySig[sharpOf] == StaffAccidental.sharp ||
              _keySig[flatOf] == StaffAccidental.flat;
          if (!covered) result.add(s);
        }
      }
    }
    return result;
  }

  void _onKeyHover(int slotIdx, int keyboard, int? semitone) {
    setState(() {
      if (semitone != null) {
        _hoveredSlot = slotIdx;
        _hoveredKeyboard = keyboard;
        _hoveredSemitone = semitone;
      } else if (_hoveredSlot == slotIdx && _hoveredKeyboard == keyboard) {
        _hoveredSlot = null;
        _hoveredKeyboard = null;
        _hoveredSemitone = null;
      }
    });
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
              activeKeys: (_hoveredSlot != null &&
                      _document.currentPage.occupiedSlots
                          .contains(_hoveredSlot!))
                  ? _document.currentPage.state[_hoveredSlot!]
                  : null,
              hoveredKeyboard: _hoveredKeyboard,
              hoveredSemitone: _hoveredSemitone,
              keySig: _keySig,
              onKeySigChanged: _onKeySigChanged,
            ),
          Expanded(
            child: PageNavigatorWidget(
              document: _document,
              onKeyTap: _toggleKey,
              onAddMeasure: _addMeasure,
              onDeleteMeasure: _deleteMeasure,
              onGoToPage: _goToPage,
              onInsertPageBefore: _insertPageBefore,
              onInsertPageAfter: _insertPageAfter,
              onDeletePage: _document.pages.length > 1 ? _deletePage : null,
              onKeyHover: _showGrandStaff ? _onKeyHover : null,
              grayedKeys: _grayedKeys,
              onSongTitleChanged: _updateSongTitle,
              onSectionLabelChanged: _updateSectionLabel,
              onChordSelected: _selectChord,
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
