import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/practice_document.dart';

class FileService {
  Future<String?> saveDocument(PracticeDocument doc) async {
    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Practice Sheet',
      fileName: 'practice_sheet.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (path == null) return null;
    final resolvedPath = path.endsWith('.json') ? path : '$path.json';
    final file = File(resolvedPath);
    await file.writeAsString(doc.toJsonString());
    return resolvedPath;
  }

  Future<PracticeDocument?> loadDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Load Practice Sheet',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return null;
    final file = File(result.files.single.path!);
    final contents = await file.readAsString();
    return PracticeDocument.fromJsonString(contents);
  }
}
