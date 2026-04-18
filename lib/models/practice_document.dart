import 'dart:convert';
import 'practice_sheet.dart';

class PracticeDocument {
  final List<PracticeSheet> pages;
  final int currentPageIndex;
  final String songTitle;

  PracticeDocument()
      : pages = [PracticeSheet()],
        currentPageIndex = 0,
        songTitle = '';

  PracticeDocument._({
    required this.pages,
    required this.currentPageIndex,
    required this.songTitle,
  });

  PracticeSheet get currentPage => pages[currentPageIndex];
  bool get hasPreviousPage => currentPageIndex > 0;
  bool get hasNextPage => currentPageIndex < pages.length - 1;

  PracticeDocument withSongTitle(String title) => PracticeDocument._(
        pages: pages,
        currentPageIndex: currentPageIndex,
        songTitle: title,
      );

  PracticeDocument withCurrentPageIndex(int index) => PracticeDocument._(
        pages: pages,
        currentPageIndex: index.clamp(0, pages.length - 1),
        songTitle: songTitle,
      );

  PracticeDocument withCurrentPageUpdated(PracticeSheet sheet) {
    final newPages = List<PracticeSheet>.from(pages);
    newPages[currentPageIndex] = sheet;
    return PracticeDocument._(
        pages: newPages, currentPageIndex: currentPageIndex, songTitle: songTitle);
  }

  PracticeDocument withPageInsertedBefore(int index) {
    final newPages = List<PracticeSheet>.from(pages)..insert(index, PracticeSheet());
    return PracticeDocument._(
        pages: newPages, currentPageIndex: index, songTitle: songTitle);
  }

  PracticeDocument withPageInsertedAfter(int index) {
    final newPages = List<PracticeSheet>.from(pages)..insert(index + 1, PracticeSheet());
    return PracticeDocument._(
        pages: newPages, currentPageIndex: index + 1, songTitle: songTitle);
  }

  Map<String, dynamic> toJson() => {
        'currentPageIndex': currentPageIndex,
        'songTitle': songTitle,
        'pages': pages.map((p) => p.toJson()).toList(),
      };

  factory PracticeDocument.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('pages')) {
      final pagesList = (json['pages'] as List)
          .map((p) => PracticeSheet.fromJson(p as Map<String, dynamic>))
          .toList();
      final idx = (json['currentPageIndex'] as int? ?? 0)
          .clamp(0, pagesList.length - 1);
      return PracticeDocument._(
        pages: pagesList,
        currentPageIndex: idx,
        songTitle: json['songTitle'] as String? ?? '',
      );
    }
    // Legacy single-page format
    return PracticeDocument._(
      pages: [PracticeSheet.fromJson(json)],
      currentPageIndex: 0,
      songTitle: '',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PracticeDocument.fromJsonString(String s) =>
      PracticeDocument.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
