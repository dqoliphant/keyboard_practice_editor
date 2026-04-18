import 'dart:convert';
import 'practice_sheet.dart';

class PracticeDocument {
  final List<PracticeSheet> pages;
  final int currentPageIndex;

  PracticeDocument()
      : pages = [PracticeSheet()],
        currentPageIndex = 0;

  PracticeDocument._({required this.pages, required this.currentPageIndex});

  PracticeSheet get currentPage => pages[currentPageIndex];
  bool get hasPreviousPage => currentPageIndex > 0;
  bool get hasNextPage => currentPageIndex < pages.length - 1;

  PracticeDocument withCurrentPageIndex(int index) => PracticeDocument._(
        pages: pages,
        currentPageIndex: index.clamp(0, pages.length - 1),
      );

  PracticeDocument withCurrentPageUpdated(PracticeSheet sheet) {
    final newPages = List<PracticeSheet>.from(pages);
    newPages[currentPageIndex] = sheet;
    return PracticeDocument._(pages: newPages, currentPageIndex: currentPageIndex);
  }

  PracticeDocument withPageInsertedBefore(int index) {
    final newPages = List<PracticeSheet>.from(pages)..insert(index, PracticeSheet());
    return PracticeDocument._(pages: newPages, currentPageIndex: index);
  }

  PracticeDocument withPageInsertedAfter(int index) {
    final newPages = List<PracticeSheet>.from(pages)..insert(index + 1, PracticeSheet());
    return PracticeDocument._(pages: newPages, currentPageIndex: index + 1);
  }

  Map<String, dynamic> toJson() => {
        'currentPageIndex': currentPageIndex,
        'pages': pages.map((p) => p.toJson()).toList(),
      };

  factory PracticeDocument.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('pages')) {
      final pagesList = (json['pages'] as List)
          .map((p) => PracticeSheet.fromJson(p as Map<String, dynamic>))
          .toList();
      final idx = (json['currentPageIndex'] as int? ?? 0)
          .clamp(0, pagesList.length - 1);
      return PracticeDocument._(pages: pagesList, currentPageIndex: idx);
    }
    // Legacy single-page format
    return PracticeDocument._(
      pages: [PracticeSheet.fromJson(json)],
      currentPageIndex: 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PracticeDocument.fromJsonString(String s) =>
      PracticeDocument.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
