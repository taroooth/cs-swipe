import 'package:csv/csv.dart';
import '../models/csv_item.dart';

class CsvParser {
  /// CSVテキストをパースしてCsvItemリストを返す
  /// 1行目をヘッダーとして使用する
  static List<CsvItem> parse(String csvText) {
    final rows = const CsvToListConverter().convert(csvText, eol: '\n');
    if (rows.isEmpty) return [];

    final headers =
        rows.first.map((e) => e.toString().trim()).toList();
    final items = <CsvItem>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((cell) => cell.toString().trim().isEmpty)) continue;

      final fields = <String, String>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        fields[headers[j]] = row[j].toString().trim();
      }
      items.add(CsvItem(id: i - 1, fields: fields));
    }

    return items;
  }
}
