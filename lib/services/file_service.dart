import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/practice_sheet.dart';

class FileService {
  Future<String?> saveSheet(PracticeSheet sheet) async {
    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Practice Sheet',
      fileName: 'practice_sheet.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (path == null) return null;
    final file = File(path);
    await file.writeAsString(sheet.toJsonString());
    return path;
  }

  Future<PracticeSheet?> loadSheet() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Load Practice Sheet',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return null;
    final file = File(result.files.single.path!);
    final contents = await file.readAsString();
    return PracticeSheet.fromJsonString(contents);
  }
}
