import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import '../models/practice_document.dart';
import 'practice_sheet_widget.dart';

const double _kPageGap = 56.0;

class PageNavigatorWidget extends StatefulWidget {
  final PracticeDocument document;
  final void Function(int slotIdx, int kb, int semi) onKeyTap;
  final void Function(int slotIdx) onAddMeasure;
  final void Function(int slotIdx) onDeleteMeasure;
  final void Function(int pageIndex) onGoToPage;
  final VoidCallback onInsertPageBefore;
  final VoidCallback onInsertPageAfter;
  final VoidCallback? onDeletePage;
  final void Function(int slotIdx, int keyboard, int? semitone)? onKeyHover;
  final void Function(int? slotIdx)? onMeasureHover;
  final Set<int> grayedKeys;
  final void Function(String) onSongTitleChanged;
  final void Function(String) onSectionLabelChanged;
  final void Function(int slotIdx, String chord) onChordSelected;

  const PageNavigatorWidget({
    super.key,
    required this.document,
    required this.onKeyTap,
    required this.onAddMeasure,
    required this.onDeleteMeasure,
    required this.onGoToPage,
    required this.onInsertPageBefore,
    required this.onInsertPageAfter,
    this.onDeletePage,
    this.onKeyHover,
    this.onMeasureHover,
    this.grayedKeys = const {},
    required this.onSongTitleChanged,
    required this.onSectionLabelChanged,
    required this.onChordSelected,
  });

  @override
  State<PageNavigatorWidget> createState() => _PageNavigatorWidgetState();
}

class _PageNavigatorWidgetState extends State<PageNavigatorWidget> {
  late final ScrollController _scrollCtrl;
  int _focusedIdx = 0;
  Timer? _snapTimer;

  double get _pageStride => kSheetWidth + _kPageGap;

  @override
  void initState() {
    super.initState();
    _focusedIdx = widget.document.currentPageIndex;
    _scrollCtrl = ScrollController(
      initialScrollOffset: _focusedIdx * _pageStride,
    );
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(PageNavigatorWidget old) {
    super.didUpdateWidget(old);
    final newIdx = widget.document.currentPageIndex;
    final insertedBefore = widget.document.pages.length == old.document.pages.length + 1 &&
        newIdx == old.document.currentPageIndex &&
        newIdx == _focusedIdx;

    if (insertedBefore) {
      final double target = _focusedIdx * _pageStride;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollCtrl.hasClients) return;
        final pos = _scrollCtrl.position;
        _scrollCtrl.jumpTo((target + _pageStride).clamp(pos.minScrollExtent, pos.maxScrollExtent));
        _scrollCtrl.animateTo(
          target.clamp(pos.minScrollExtent, pos.maxScrollExtent),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      });
    } else if (newIdx != _focusedIdx) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToPage(newIdx);
      });
    }
  }

  @override
  void dispose() {
    _snapTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final maxIdx = widget.document.pages.length - 1;
    final newIdx = (_scrollCtrl.offset / _pageStride).round().clamp(0, maxIdx);
    if (newIdx != _focusedIdx) {
      setState(() => _focusedIdx = newIdx);
      widget.onGoToPage(newIdx);
    }
  }

  void _scrollToPage(int idx) {
    setState(() => _focusedIdx = idx);
    widget.onGoToPage(idx);
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      (idx * _pageStride).clamp(
        _scrollCtrl.position.minScrollExtent,
        _scrollCtrl.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _snapToNearestPage() {
    if (!_scrollCtrl.hasClients) return;
    final maxIdx = widget.document.pages.length - 1;
    final idx = (_scrollCtrl.offset / _pageStride).round().clamp(0, maxIdx);
    final target = idx * _pageStride;
    if ((_scrollCtrl.offset - target).abs() < 1.0) return;
    _scrollToPage(idx);
  }

  void _onWheelScroll(PointerScrollEvent event) {
    if (!_scrollCtrl.hasClients) return;
    final delta = event.scrollDelta.dy.abs() >= event.scrollDelta.dx.abs()
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    _scrollCtrl.jumpTo(
      (_scrollCtrl.offset + delta).clamp(
        _scrollCtrl.position.minScrollExtent,
        _scrollCtrl.position.maxScrollExtent,
      ),
    );
    _snapTimer?.cancel();
    _snapTimer = Timer(const Duration(milliseconds: 200), _snapToNearestPage);
  }

  Widget _buildPageCell(int i) {
    final sheet = widget.document.pages[i];
    final songTitle = widget.document.songTitle;
    if (i == _focusedIdx) {
      return PracticeSheetWidget(
        sheet: sheet,
        songTitle: songTitle,
        onKeyTap: widget.onKeyTap,
        onAddMeasure: widget.onAddMeasure,
        onDeleteMeasure: widget.onDeleteMeasure,
        onDeletePage: widget.onDeletePage,
        onKeyHover: widget.onKeyHover,
        onMeasureHover: widget.onMeasureHover,
        grayedKeys: widget.grayedKeys,
        onSongTitleChanged: widget.onSongTitleChanged,
        onSectionLabelChanged: widget.onSectionLabelChanged,
        onChordSelected: widget.onChordSelected,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _scrollToPage(i),
      child: IgnorePointer(
        child: PracticeSheetWidget(
          sheet: sheet,
          songTitle: songTitle,
          onKeyTap: (a, b, c) {},
          onAddMeasure: (a) {},
          onDeleteMeasure: (a) {},
          onSongTitleChanged: (_) {},
          onSectionLabelChanged: (_) {},
          onChordSelected: (a, b) {},
        ),
      ),
    );
  }

  Widget _buildGapCell(double width, VoidCallback? onInsert) {
    return SizedBox(
      width: width,
      height: kSheetHeight,
      child: onInsert != null ? Center(child: _AddPageButton(onTap: onInsert)) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final double W = constraints.maxWidth;
      final double H = constraints.maxHeight;
      final double sidePad = math.max(0, (W - kSheetWidth) / 2);
      final int pageCount = widget.document.pages.length;

      // Edge gap cells use the same _kPageGap width as inter-page gaps so the
      // button center lands at _kPageGap/2 (28 px) from the page edge.
      final double edgeInner = math.min(_kPageGap, sidePad);
      final double edgeOuter = math.max(0, sidePad - _kPageGap);

      return NotificationListener<UserScrollNotification>(
        onNotification: (n) {
          if (n.direction == ScrollDirection.idle) _snapToNearestPage();
          return false;
        },
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) _onWheelScroll(event);
          },
          child: SizedBox(
            width: W,
            height: H,
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                height: H,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: edgeOuter),
                    _buildGapCell(
                      edgeInner,
                      _focusedIdx == 0 ? widget.onInsertPageBefore : null,
                    ),
                    for (int i = 0; i < pageCount; i++) ...[
                      _buildPageCell(i),
                      if (i < pageCount - 1)
                        _buildGapCell(
                          _kPageGap,
                          i == _focusedIdx
                              ? widget.onInsertPageAfter
                              : (i + 1 == _focusedIdx
                                  ? widget.onInsertPageBefore
                                  : null),
                        ),
                    ],
                    _buildGapCell(
                      edgeInner,
                      _focusedIdx == pageCount - 1
                          ? widget.onInsertPageAfter
                          : null,
                    ),
                    SizedBox(width: edgeOuter),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------

class _AddPageButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddPageButton({required this.onTap});

  @override
  State<_AddPageButton> createState() => _AddPageButtonState();
}

class _AddPageButtonState extends State<_AddPageButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered ? const Color(0xFF4A90D9) : Colors.white,
            border: Border.all(
              color:
                  _hovered ? const Color(0xFF4A90D9) : const Color(0xFFBBBBBB),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            size: 20,
            color: _hovered ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}
