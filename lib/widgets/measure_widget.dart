import 'package:flutter/material.dart';
import '../models/chord_detector.dart';
import '../models/guitar_chord_data.dart';
import 'guitar_chord_diagram_widget.dart';
import 'piano_keyboard_painter.dart';

class MeasureWidget extends StatefulWidget {
  final int measureNumber;
  final List<List<bool>> keyboards; // [2][24]
  final List<List<int>> fingerNumbers; // [2][24]
  final String? chordOverride;
  final GuitarChordData? guitarChordData; // non-null = guitar mode
  final void Function(int keyboardIdx, int semitone) onKeyTap;
  final void Function(int keyboardIdx, int semitone) onKeyFingerCycle;
  final VoidCallback onCopy;
  final VoidCallback? onPasteValues;
  final void Function(String chord) onChordSelected;
  final VoidCallback onDelete;
  final void Function(int keyboard, int? semitone)? onKeyHover;
  final VoidCallback? onMeasureEnter;
  final VoidCallback? onMeasureExit;
  final Set<int> grayedKeys;
  // Guitar callbacks
  final void Function(int stringIdx, int fretAbsolute)? onGuitarFretTapped;
  final void Function(int stringIdx)? onGuitarStringHeaderTapped;
  final void Function(int stringIdx)? onGuitarFingerCycled;
  final void Function(String name)? onGuitarChordNameChanged;
  final VoidCallback? onConvertToGuitar;
  final VoidCallback? onConvertToPiano;
  final void Function(int delta)? onGuitarStartFretChanged;

  const MeasureWidget({
    super.key,
    required this.measureNumber,
    required this.keyboards,
    required this.fingerNumbers,
    required this.chordOverride,
    this.guitarChordData,
    required this.onKeyTap,
    required this.onKeyFingerCycle,
    required this.onCopy,
    this.onPasteValues,
    required this.onChordSelected,
    required this.onDelete,
    this.onKeyHover,
    this.onMeasureEnter,
    this.onMeasureExit,
    this.grayedKeys = const {},
    this.onGuitarFretTapped,
    this.onGuitarStringHeaderTapped,
    this.onGuitarFingerCycled,
    this.onGuitarChordNameChanged,
    this.onConvertToGuitar,
    this.onConvertToPiano,
    this.onGuitarStartFretChanged,
  });

  @override
  State<MeasureWidget> createState() => _MeasureWidgetState();
}

class _MeasureWidgetState extends State<MeasureWidget> {
  // Tracks which key (if any) the pointer is currently over, so the outer
  // secondary-tap handler knows whether to show the delete menu or let the
  // key's own right-click handler take precedence.
  int? _hoveredSemitone;

  bool get _isGuitar => widget.guitarChordData != null;

  void _showPianoContextMenu(Offset globalPos) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx, globalPos.dy, globalPos.dx, globalPos.dy,
      ),
      items: [
        const PopupMenuItem(value: 'copy', child: Text('Copy')),
        if (widget.onPasteValues != null)
          const PopupMenuItem(value: 'paste_values', child: Text('Paste Values')),
        const PopupMenuDivider(),
        if (widget.onConvertToGuitar != null)
          const PopupMenuItem(value: 'to_guitar', child: Text('Convert to Guitar Chord')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete', child: Text('Delete measure')),
      ],
    );
    if (result == 'copy') widget.onCopy();
    if (result == 'paste_values') widget.onPasteValues?.call();
    if (result == 'to_guitar') widget.onConvertToGuitar?.call();
    if (result == 'delete') widget.onDelete();
  }

  void _onKeyHover(int kb, int? semitone) {
    setState(() => _hoveredSemitone = semitone);
    widget.onKeyHover?.call(kb, semitone);
  }

  @override
  Widget build(BuildContext context) {
    if (_isGuitar) {
      return MouseRegion(
        onEnter: (_) => widget.onMeasureEnter?.call(),
        onExit: (_) => widget.onMeasureExit?.call(),
        child: GuitarChordDiagramWidget(
          measureNumber: widget.measureNumber,
          chord: widget.guitarChordData!,
          onFretTapped: widget.onGuitarFretTapped ?? (_, __) {},
          onStringHeaderTapped: widget.onGuitarStringHeaderTapped ?? (_) {},
          onFingerCycled: widget.onGuitarFingerCycled ?? (_) {},
          onChordNameChanged: widget.onGuitarChordNameChanged ?? (_) {},
          onCopy: widget.onCopy,
          onPasteValues: widget.onPasteValues,
          onDelete: widget.onDelete,
          onConvertToPiano: widget.onConvertToPiano,
          onStartFretChanged: widget.onGuitarStartFretChanged ?? (_) {},
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => widget.onMeasureEnter?.call(),
      onExit: (_) => widget.onMeasureExit?.call(),
      child: GestureDetector(
        onSecondaryTapUp: (d) {
          if (_hoveredSemitone == null) _showPianoContextMenu(d.globalPosition);
        },
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ChordHeader(
                measureNumber: widget.measureNumber,
                keyboards: widget.keyboards,
                chordOverride: widget.chordOverride,
                onChordSelected: widget.onChordSelected,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                  child: PianoKeyboardWidget(
                    activeKeys: widget.keyboards[0],
                    fingerNumbers: widget.fingerNumbers[0],
                    onKeyTap: (semi) => widget.onKeyTap(0, semi),
                    onKeyRightClick: (semi) => widget.onKeyFingerCycle(0, semi),
                    onKeyHover: (s) => _onKeyHover(0, s),
                    grayedKeys: widget.grayedKeys,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: PianoKeyboardWidget(
                    activeKeys: widget.keyboards[1],
                    fingerNumbers: widget.fingerNumbers[1],
                    onKeyTap: (semi) => widget.onKeyTap(1, semi),
                    onKeyRightClick: (semi) => widget.onKeyFingerCycle(1, semi),
                    onKeyHover: (s) => _onKeyHover(1, s),
                    grayedKeys: widget.grayedKeys,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
