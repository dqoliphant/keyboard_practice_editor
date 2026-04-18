import 'package:flutter/material.dart';
import 'piano_keyboard_painter.dart';

class MeasureWidget extends StatelessWidget {
  final int measureNumber;
  final List<List<bool>> keyboards; // [2][24]
  final void Function(int keyboardIdx, int semitone) onKeyTap;

  const MeasureWidget({
    super.key,
    required this.measureNumber,
    required this.keyboards,
    required this.onKeyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF444444), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 16.0,
            child: Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: Text(
                '$measureNumber',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: PianoKeyboardWidget(
              activeKeys: keyboards[0],
              onKeyTap: (semi) => onKeyTap(0, semi),
            ),
          ),
          const SizedBox(height: 3.0),
          Expanded(
            child: PianoKeyboardWidget(
              activeKeys: keyboards[1],
              onKeyTap: (semi) => onKeyTap(1, semi),
            ),
          ),
        ],
      ),
    );
  }
}
