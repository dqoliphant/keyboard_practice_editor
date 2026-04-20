import 'package:flutter/material.dart';
import '../models/practice_sheet.dart';
import 'measure_widget.dart';

// 11x8.5" at 96dpi
const double kSheetWidth = 1056.0;
const double kSheetHeight = 816.0;
const double kSheetPadding = 20.0;
const double kSheetHeaderHeight = 60.0;

class PracticeSheetWidget extends StatelessWidget {
  final PracticeSheet sheet;
  final String songTitle;
  final void Function(int slotIdx, int keyboard, int semitone) onKeyTap;
  final void Function(int slotIdx) onAddMeasure;
  final void Function(int slotIdx) onDeleteMeasure;
  final VoidCallback? onDeletePage;
  final void Function(String) onSongTitleChanged;
  final void Function(String) onSectionLabelChanged;
  final void Function(int slotIdx, String chord) onChordSelected;

  const PracticeSheetWidget({
    super.key,
    required this.sheet,
    required this.songTitle,
    required this.onKeyTap,
    required this.onAddMeasure,
    required this.onDeleteMeasure,
    this.onDeletePage,
    required this.onSongTitleChanged,
    required this.onSectionLabelChanged,
    required this.onChordSelected,
  });

  Widget _cellForSlot(int slotIdx) {
    if (sheet.occupiedSlots.contains(slotIdx)) {
      return MeasureWidget(
        measureNumber: sheet.measureNumberForSlot(slotIdx),
        keyboards: sheet.state[slotIdx],
        chordOverride: sheet.chordOverrides[slotIdx],
        onKeyTap: (kb, semi) => onKeyTap(slotIdx, kb, semi),
        onChordSelected: (chord) => onChordSelected(slotIdx, chord),
        onDelete: () => onDeleteMeasure(slotIdx),
      );
    }
    final persistent = slotIdx == sheet.firstUnoccupiedSlot;
    return _EmptySlotCell(
      persistent: persistent,
      onTap: () => onAddMeasure(slotIdx),
    );
  }

  List<Widget> _buildRows() {
    const double rowGap = 8.0;
    const double colGap = 8.0;
    final rows = <Widget>[];
    for (int row = 0; row < 3; row++) {
      if (row > 0) rows.add(const SizedBox(height: rowGap));
      final cells = <Widget>[];
      for (int col = 0; col < 4; col++) {
        if (col > 0) cells.add(const SizedBox(width: colGap));
        cells.add(Expanded(child: _cellForSlot(row * 4 + col)));
      }
      rows.add(Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cells,
        ),
      ));
    }
    return rows;
  }

  void _showPageMenu(BuildContext context, Offset globalPos) async {
    if (onDeletePage == null) return;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx, globalPos.dy, globalPos.dx, globalPos.dy,
      ),
      items: const [
        PopupMenuItem(value: 'delete', child: Text('Delete Page')),
      ],
    );
    if (result == 'delete') onDeletePage!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: onDeletePage != null
          ? (d) => _showPageMenu(context, d.globalPosition)
          : null,
      child: Container(
      width: kSheetWidth,
      height: kSheetHeight,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(kSheetPadding),
        child: Column(
          children: [
            _SheetHeaderWidget(
              songTitle: songTitle,
              sectionLabel: sheet.sectionLabel,
              onSongTitleChanged: onSongTitleChanged,
              onSectionLabelChanged: onSectionLabelChanged,
            ),
            ..._buildRows(),
          ],
        ),
      ),
    ));
  }
}

// ---------------------------------------------------------------------------

class _SheetHeaderWidget extends StatefulWidget {
  final String songTitle;
  final String sectionLabel;
  final void Function(String) onSongTitleChanged;
  final void Function(String) onSectionLabelChanged;

  const _SheetHeaderWidget({
    required this.songTitle,
    required this.sectionLabel,
    required this.onSongTitleChanged,
    required this.onSectionLabelChanged,
  });

  @override
  State<_SheetHeaderWidget> createState() => _SheetHeaderWidgetState();
}

class _SheetHeaderWidgetState extends State<_SheetHeaderWidget> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _sectionCtrl;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _sectionFocus = FocusNode();
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.songTitle);
    _sectionCtrl = TextEditingController(text: widget.sectionLabel);
    _titleFocus.addListener(() => setState(() {}));
    _sectionFocus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(_SheetHeaderWidget old) {
    super.didUpdateWidget(old);
    if (widget.songTitle != _titleCtrl.text) _titleCtrl.text = widget.songTitle;
    if (widget.sectionLabel != _sectionCtrl.text) _sectionCtrl.text = widget.sectionLabel;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _sectionCtrl.dispose();
    _titleFocus.dispose();
    _sectionFocus.dispose();
    super.dispose();
  }

  bool get _showTitle =>
      widget.songTitle.isNotEmpty || _titleFocus.hasFocus || _hovered;
  bool get _showSection =>
      widget.sectionLabel.isNotEmpty || _sectionFocus.hasFocus || _hovered;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (_showTitle) {
      children.add(TextField(
        controller: _titleCtrl,
        focusNode: _titleFocus,
        textAlign: TextAlign.center,
        onChanged: widget.onSongTitleChanged,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
          height: 1.2,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Song Title',
          hintStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCCCCCC),
            height: 1.2,
          ),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }

    if (_showTitle && _showSection) children.add(const SizedBox(height: 4));

    if (_showSection) {
      children.add(TextField(
        controller: _sectionCtrl,
        focusNode: _sectionFocus,
        textAlign: TextAlign.center,
        onChanged: widget.onSectionLabelChanged,
        style: const TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: Color(0xFF666666),
          height: 1.2,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Section',
          hintStyle: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: Color(0xFFCCCCCC),
            height: 1.2,
          ),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        height: kSheetHeaderHeight,
        child: Center(
          child: children.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// An unoccupied grid slot.
/// [persistent] = true  → always shows the + button (the first empty slot).
/// [persistent] = false → shows + only on hover.
class _EmptySlotCell extends StatefulWidget {
  final bool persistent;
  final VoidCallback onTap;

  const _EmptySlotCell({required this.persistent, required this.onTap});

  @override
  State<_EmptySlotCell> createState() => _EmptySlotCellState();
}

class _EmptySlotCellState extends State<_EmptySlotCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool show = widget.persistent || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: show ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: show
              ? BoxDecoration(
                  color: _hovered
                      ? const Color(0xFFEDF4FC)
                      : const Color(0xFFF7F7F7),
                  border: Border.all(
                    color: _hovered
                        ? const Color(0xFF4A90D9)
                        : const Color(0xFFCCCCCC),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(2),
                )
              : const BoxDecoration(color: Colors.transparent),
          child: show
              ? Center(
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 32,
                    color: _hovered
                        ? const Color(0xFF4A90D9)
                        : const Color(0xFFBBBBBB),
                  ),
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}
