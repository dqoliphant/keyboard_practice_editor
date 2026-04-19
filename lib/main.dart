import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'models/practice_document.dart';
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
      body: PageNavigatorWidget(
        document: _document,
        onKeyTap: _toggleKey,
        onAddMeasure: _addMeasure,
        onDeleteMeasure: _deleteMeasure,
        onGoToPage: _goToPage,
        onInsertPageBefore: _insertPageBefore,
        onInsertPageAfter: _insertPageAfter,
        onSongTitleChanged: _updateSongTitle,
        onSectionLabelChanged: _updateSectionLabel,
        onChordSelected: _selectChord,
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
