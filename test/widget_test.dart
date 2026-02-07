import 'package:flutter_test/flutter_test.dart';
import 'package:csv_swipe/models/csv_item.dart';
import 'package:csv_swipe/services/csv_parser.dart';

void main() {
  group('CsvItem', () {
    test('serialization roundtrip', () {
      final item = CsvItem(
        id: 0,
        fields: {'Name': 'Alice', 'Age': '30'},
        status: SwipeStatus.ok,
      );
      final json = item.toJson();
      final restored = CsvItem.fromJson(json);

      expect(restored.id, 0);
      expect(restored.fields['Name'], 'Alice');
      expect(restored.status, SwipeStatus.ok);
    });

    test('encodeList/decodeList roundtrip', () {
      final items = [
        CsvItem(id: 0, fields: {'A': '1'}),
        CsvItem(id: 1, fields: {'A': '2'}, status: SwipeStatus.confirmed),
      ];
      final encoded = CsvItem.encodeList(items);
      final decoded = CsvItem.decodeList(encoded);

      expect(decoded.length, 2);
      expect(decoded[1].status, SwipeStatus.confirmed);
    });
  });

  group('CsvParser', () {
    test('parses CSV with headers', () {
      const csv = 'Name,Age,City\nAlice,30,Tokyo\nBob,25,Osaka\n';
      final items = CsvParser.parse(csv);

      expect(items.length, 2);
      expect(items[0].fields['Name'], 'Alice');
      expect(items[0].fields['Age'], '30');
      expect(items[1].fields['City'], 'Osaka');
    });

    test('handles empty CSV', () {
      const csv = '';
      final items = CsvParser.parse(csv);
      expect(items.length, 0);
    });

    test('skips empty rows', () {
      const csv = 'Name,Age\nAlice,30\n,,\nBob,25\n';
      final items = CsvParser.parse(csv);
      expect(items.length, 2);
    });
  });

  group('SwipeStatus', () {
    test('label returns correct Japanese text', () {
      expect(SwipeStatus.ok.label, 'OK');
      expect(SwipeStatus.confirmed.label, '確認');
      expect(SwipeStatus.skipped.label, 'スキップ');
      expect(SwipeStatus.unreviewed.label, '未レビュー');
    });

    test('fromKey returns correct status', () {
      expect(SwipeStatusExtension.fromKey('ok'), SwipeStatus.ok);
      expect(SwipeStatusExtension.fromKey('confirmed'), SwipeStatus.confirmed);
      expect(SwipeStatusExtension.fromKey('invalid'), SwipeStatus.unreviewed);
    });
  });
}
