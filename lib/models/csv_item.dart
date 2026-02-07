import 'dart:convert';

enum SwipeStatus {
  unreviewed,
  ok,       // 左スワイプ
  confirmed, // 右スワイプ (確認)
  skipped,   // 上スワイプ
}

extension SwipeStatusExtension on SwipeStatus {
  String get label {
    switch (this) {
      case SwipeStatus.unreviewed:
        return '未レビュー';
      case SwipeStatus.ok:
        return 'OK';
      case SwipeStatus.confirmed:
        return '確認';
      case SwipeStatus.skipped:
        return 'スキップ';
    }
  }

  String get key {
    return name;
  }

  static SwipeStatus fromKey(String key) {
    return SwipeStatus.values.firstWhere(
      (e) => e.name == key,
      orElse: () => SwipeStatus.unreviewed,
    );
  }
}

class CsvItem {
  final int id;
  final Map<String, String> fields;
  SwipeStatus status;

  CsvItem({
    required this.id,
    required this.fields,
    this.status = SwipeStatus.unreviewed,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fields': fields,
        'status': status.key,
      };

  factory CsvItem.fromJson(Map<String, dynamic> json) => CsvItem(
        id: json['id'] as int,
        fields: Map<String, String>.from(json['fields'] as Map),
        status: SwipeStatusExtension.fromKey(json['status'] as String),
      );

  static String encodeList(List<CsvItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<CsvItem> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list
        .map((e) => CsvItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
