import 'package:flutter/material.dart';
import '../models/practice_sheet.dart';
import 'measure_widget.dart';

// 11x8.5" at 96dpi
const double kSheetWidth = 1056.0;
const double kSheetHeight = 816.0;
const double kSheetPadding = 20.0;

class PracticeSheetWidget extends StatelessWidget {
  final PracticeSheet sheet;
  final void Function(int slotIdx, int keyboard, int semitone) onKeyTap;
  final void Function(int slotIdx) onAddMeasure;

  const PracticeSheetWidget({
    super.key,
    required this.sheet,
    required this.onKeyTap,
    required this.onAddMeasure,
  });

  Widget _cellForSlot(int slotIdx) {
    if (sheet.occupiedSlots.contains(slotIdx)) {
      return MeasureWidget(
        measureNumber: sheet.measureNumberForSlot(slotIdx),
        keyboards: sheet.state[slotIdx],
        onKeyTap: (kb, semi) => onKeyTap(slotIdx, kb, semi),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kSheetWidth,
      height: kSheetHeight,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(kSheetPadding),
        child: Column(
          children: _buildRows(),
        ),
      ),
    );
  }
}

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
