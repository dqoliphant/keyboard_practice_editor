import 'package:flutter/material.dart';
import '../models/practice_sheet.dart';
import 'measure_widget.dart';

// 11x8.5" at 96dpi
const double kSheetWidth = 1056.0;
const double kSheetHeight = 816.0;
const double kSheetPadding = 20.0;

class PracticeSheetWidget extends StatelessWidget {
  final PracticeSheet sheet;
  final void Function(int measure, int keyboard, int semitone) onKeyTap;

  const PracticeSheetWidget({
    super.key,
    required this.sheet,
    required this.onKeyTap,
  });

  List<Widget> _buildRows() {
    const double rowGap = 8.0;
    const double colGap = 8.0;
    final rows = <Widget>[];
    for (int row = 0; row < 3; row++) {
      if (row > 0) rows.add(const SizedBox(height: rowGap));
      final cells = <Widget>[];
      for (int col = 0; col < 4; col++) {
        if (col > 0) cells.add(const SizedBox(width: colGap));
        final int measureIdx = row * 4 + col;
        cells.add(Expanded(
          child: MeasureWidget(
            measureNumber: measureIdx + 1,
            keyboards: sheet.state[measureIdx],
            onKeyTap: (kb, semi) => onKeyTap(measureIdx, kb, semi),
          ),
        ));
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
