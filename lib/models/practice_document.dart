import 'dart:convert';
import 'practice_sheet.dart';
import 'staff_accidental.dart';

export 'staff_accidental.dart';

class PracticeDocument {
  final List<PracticeSheet> pages;
  final int currentPageIndex;
  final String songTitle;
  final Map<int, StaffAccidental> keySig;

  PracticeDocument()
      : pages = [PracticeSheet()],
        currentPageIndex = 0,
        songTitle = '',
        keySig = const {};

  PracticeDocument._({
    required this.pages,
    required this.currentPageIndex,
    required this.songTitle,
    this.keySig = const {},
  });

  PracticeSheet get currentPage => pages[currentPageIndex];
  bool get hasPreviousPage => currentPageIndex > 0;
  bool get hasNextPage => currentPageIndex < pages.length - 1;

  PracticeDocument withSongTitle(String title) => PracticeDocument._(
        pages: pages, currentPageIndex: currentPageIndex,
        songTitle: title, keySig: keySig,
      );

  PracticeDocument withCurrentPageIndex(int index) => PracticeDocument._(
        pages: pages, currentPageIndex: index.clamp(0, pages.length - 1),
        songTitle: songTitle, keySig: keySig,
      );

  PracticeDocument withCurrentPageUpdated(PracticeSheet sheet) {
    final newPages = List<PracticeSheet>.from(pages);
    newPages[currentPageIndex] = sheet;
    return PracticeDocument._(
        pages: newPages, currentPageIndex: currentPageIndex,
        songTitle: songTitle, keySig: keySig);
  }

  PracticeDocument withPageInsertedBefore(int index) {
    final newPages = List<PracticeSheet>.from(pages)..insert(index, PracticeSheet());
    return PracticeDocument._(
        pages: newPages, currentPageIndex: index,
        songTitle: songTitle, keySig: keySig);
  }

  PracticeDocument withPageInsertedAfter(int index) {
    final newPages = List<PracticeSheet>.from(pages)..insert(index + 1, PracticeSheet());
    return PracticeDocument._(
        pages: newPages, currentPageIndex: index + 1,
        songTitle: songTitle, keySig: keySig);
  }

  PracticeDocument withPageDeleted(int index) {
    if (pages.length <= 1) return this;
    final newPages = List<PracticeSheet>.from(pages)..removeAt(index);
    final newIdx = index.clamp(0, newPages.length - 1);
    return PracticeDocument._(
        pages: newPages, currentPageIndex: newIdx,
        songTitle: songTitle, keySig: keySig);
  }

  PracticeDocument withKeySig(Map<int, StaffAccidental> sig) => PracticeDocument._(
        pages: pages, currentPageIndex: currentPageIndex,
        songTitle: songTitle, keySig: sig,
      );

  static Map<int, StaffAccidental> _keySigFromJson(Map<String, dynamic>? json) {
    if (json == null) return const {};
    return {
      for (final e in json.entries)
        int.parse(e.key): e.value == 'sharp' ? StaffAccidental.sharp : StaffAccidental.flat,
    };
  }

  Map<String, dynamic> toJson() => {
        'currentPageIndex': currentPageIndex,
        'songTitle': songTitle,
        'pages': pages.map((p) => p.toJson()).toList(),
        'keySig': {
          for (final e in keySig.entries)
            '${e.key}': e.value == StaffAccidental.sharp ? 'sharp' : 'flat',
        },
      };

  factory PracticeDocument.fromJson(Map<String, dynamic> json) {
    final sig = _keySigFromJson(json['keySig'] as Map<String, dynamic>?);
    if (json.containsKey('pages')) {
      final pagesList = (json['pages'] as List)
          .map((p) => PracticeSheet.fromJson(p as Map<String, dynamic>))
          .toList();
      final idx = (json['currentPageIndex'] as int? ?? 0)
          .clamp(0, pagesList.length - 1);
      return PracticeDocument._(
        pages: pagesList, currentPageIndex: idx,
        songTitle: json['songTitle'] as String? ?? '', keySig: sig,
      );
    }
    // Legacy single-page format
    return PracticeDocument._(
      pages: [PracticeSheet.fromJson(json)],
      currentPageIndex: 0, songTitle: '', keySig: sig,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PracticeDocument.fromJsonString(String s) =>
      PracticeDocument.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
