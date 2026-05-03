import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../logging/app_log.dart';
import 'save_data.dart';

class RogueliteSaveService {
  static const _fileName = 'roguelite_save.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<RogueliteSaveData?> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return null;
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final data = RogueliteSaveData.fromJson(json);
      appLog.info('save', 'save.load_ok');
      return data;
    } catch (e) {
      appLog.warn(
        'save',
        'save.load_failed',
        cid: 'save-file-1',
        ctx: {'reason': 'parse_error'},
      );
      return null;
    }
  }

  Future<void> save(RogueliteSaveData data) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(data.toJson()));
    } catch (e) {
      appLog.warn(
        'save',
        'save.write_failed',
        cid: 'save-file-2',
        ctx: {'reason': 'write_error'},
      );
    }
  }
}
