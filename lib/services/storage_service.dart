import 'package:shared_preferences/shared_preferences.dart';
import '../models/csv_item.dart';

class StorageService {
  static const _key = 'csv_items';
  static const _headersKey = 'csv_headers';

  static Future<void> saveItems(List<CsvItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, CsvItem.encodeList(items));
  }

  static Future<List<CsvItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null || json.isEmpty) return [];
    return CsvItem.decodeList(json);
  }

  static Future<void> saveHeaders(List<String> headers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_headersKey, headers);
  }

  static Future<List<String>> loadHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_headersKey) ?? [];
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_headersKey);
  }
}
