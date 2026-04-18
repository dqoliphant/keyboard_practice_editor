import 'package:flutter/material.dart';
import 'models/practice_sheet.dart';
import 'widgets/practice_sheet_widget.dart';
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
  PracticeSheet _sheet = PracticeSheet();
  final _fileService = FileService();
  final _pdfService = PdfService();
  bool _busy = false;

  void _toggleKey(int measure, int keyboard, int semitone) {
    setState(() {
      _sheet.toggle(measure, keyboard, semitone);
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await _fileService.saveSheet(_sheet);
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final loaded = await _fileService.loadSheet();
      if (loaded != null && mounted) {
        setState(() => _sheet = loaded);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _pdfService.printOrExport(_sheet);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addMeasure(int slotIdx) {
    setState(() => _sheet = _sheet.withSlotAdded(slotIdx));
  }

  void _deleteMeasure(int slotIdx) {
    setState(() => _sheet = _sheet.withSlotRemoved(slotIdx));
  }

  void _clear() {
    setState(() => _sheet = PracticeSheet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        title: const Text('Keyboard Practice Editor'),
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
            label: const Text(
              'Print / Export PDF',
              style: TextStyle(color: Colors.white70),
            ),
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
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: PracticeSheetWidget(
                sheet: _sheet,
                onKeyTap: _toggleKey,
                onAddMeasure: _addMeasure,
                onDeleteMeasure: _deleteMeasure,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
