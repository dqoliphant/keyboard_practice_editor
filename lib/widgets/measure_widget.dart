import 'package:flutter/material.dart';
import '../models/chord_detector.dart';
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
            height: 18.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$measureNumber',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      detectChord(keyboards) ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PianoKeyboardWidget(
              activeKeys: keyboards[0],
              onKeyTap: (semi) => onKeyTap(0, semi),
            ),
          ),
          const SizedBox(height: 10.0),
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
