import 'package:flutter/material.dart';
import '../models/chord_detector.dart';
import 'piano_keyboard_painter.dart';

class MeasureWidget extends StatelessWidget {
  final int measureNumber;
  final List<List<bool>> keyboards; // [2][24]
  final String? chordOverride;
  final void Function(int keyboardIdx, int semitone) onKeyTap;
  final void Function(String chord) onChordSelected;
  final VoidCallback onDelete;
  final void Function(int keyboard, int? semitone)? onKeyHover;
  final VoidCallback? onMeasureEnter;
  final VoidCallback? onMeasureExit;
  final Set<int> grayedKeys;

  const MeasureWidget({
    super.key,
    required this.measureNumber,
    required this.keyboards,
    required this.chordOverride,
    required this.onKeyTap,
    required this.onChordSelected,
    required this.onDelete,
    this.onKeyHover,
    this.onMeasureEnter,
    this.onMeasureExit,
    this.grayedKeys = const {},
  });

  void _showContextMenu(BuildContext context, Offset globalPos) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx, globalPos.dy, globalPos.dx, globalPos.dy,
      ),
      items: const [
        PopupMenuItem(value: 'delete', child: Text('Delete measure')),
      ],
    );
    if (result == 'delete') onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onMeasureEnter?.call(),
      onExit: (_) => onMeasureExit?.call(),
      child: GestureDetector(
      onSecondaryTapUp: (d) => _showContextMenu(context, d.globalPosition),
      child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF444444), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChordHeader(
            measureNumber: measureNumber,
            keyboards: keyboards,
            chordOverride: chordOverride,
            onChordSelected: onChordSelected,
          ),
          Expanded(
            child: PianoKeyboardWidget(
              activeKeys: keyboards[0],
              onKeyTap: (semi) => onKeyTap(0, semi),
              onKeyHover: (s) => onKeyHover?.call(0, s),
              grayedKeys: grayedKeys,
            ),
          ),
          const SizedBox(height: 10.0),
          Expanded(
            child: PianoKeyboardWidget(
              activeKeys: keyboards[1],
              onKeyTap: (semi) => onKeyTap(1, semi),
              onKeyHover: (s) => onKeyHover?.call(1, s),
              grayedKeys: grayedKeys,
            ),
          ),
        ],
      ),
    )));
  }
}

// ---------------------------------------------------------------------------

class _ChordHeader extends StatelessWidget {
  final int measureNumber;
  final List<List<bool>> keyboards;
  final String? chordOverride;
  final void Function(String) onChordSelected;

  const _ChordHeader({
    required this.measureNumber,
    required this.keyboards,
    required this.chordOverride,
    required this.onChordSelected,
  });

  static const double _itemH = 40.0;
  static const double _menuVertPad = 8.0; // Flutter's kMenuVerticalPadding

  void _openChordMenu(
      BuildContext context, Offset tapPos, List<String> chords, int activeIdx) async {
    // Position the menu so the active item's centre lands at the tap point.
    final double menuTop =
        tapPos.dy - _menuVertPad - activeIdx * _itemH - _itemH / 2;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPos.dx - 48, menuTop, tapPos.dx + 48, menuTop,
      ),
      items: chords.asMap().entries.map((e) {
        final isActive = e.key == activeIdx;
        return PopupMenuItem<String>(
          value: e.value,
          height: _itemH,
          child: Text(
            e.value,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color:
                  isActive ? const Color(0xFF1A1A1A) : const Color(0xFF555555),
            ),
          ),
        );
      }).toList(),
    );

    if (selected != null) onChordSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final allChords = detectAllChords(keyboards);

    String? activeChord;
    int activeIdx = 0;
    if (allChords.isNotEmpty) {
      final overrideIdx =
          chordOverride != null ? allChords.indexOf(chordOverride!) : -1;
      activeIdx = overrideIdx >= 0 ? overrideIdx : 0;
      activeChord = allChords[activeIdx];
    }

    final hasAlternatives = allChords.length > 1;

    Widget? chordWidget;
    if (activeChord != null) {
      final label = Text(
        activeChord,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      );
      chordWidget = hasAlternatives
          ? GestureDetector(
              onTapUp: (d) => _openChordMenu(
                  context, d.globalPosition, allChords, activeIdx),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: label,
              ),
            )
          : label;
    }

    return SizedBox(
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
              child: Center(child: chordWidget ?? const SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }
}
