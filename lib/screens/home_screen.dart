import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/csv_item.dart';
import '../services/csv_parser.dart';
import '../services/storage_service.dart';
import 'swipe_screen.dart';
import 'list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  List<CsvItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await StorageService.loadItems();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final csvText = await File(filePath).readAsString();
      final items = CsvParser.parse(csvText);

      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSVにデータが見つかりませんでした')),
          );
        }
        return;
      }

      // 追加 or 置換の確認
      if (_items.isNotEmpty) {
        final action = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('インポート方法'),
            content: Text('${items.length}件のデータが見つかりました'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'replace'),
                child: const Text('置換'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'append'),
                child: const Text('追加'),
              ),
            ],
          ),
        );
        if (action == null || action == 'cancel') return;
        if (action == 'replace') {
          _items = items;
        } else {
          // 追加の場合、IDを振り直す
          final offset = _items.length;
          for (var i = 0; i < items.length; i++) {
            items[i] = CsvItem(
              id: offset + i,
              fields: items[i].fields,
            );
          }
          _items.addAll(items);
        }
      } else {
        _items = items;
      }

      await StorageService.saveItems(_items);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${items.length}件をインポートしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _resetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('データリセット'),
        content: const Text('全てのデータを削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await StorageService.clear();
    setState(() {
      _items = [];
    });
  }

  Future<void> _resetStatuses() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ステータスリセット'),
        content: const Text('全アイテムのステータスを未レビューに戻しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    for (final item in _items) {
      item.status = SwipeStatus.unreviewed;
    }
    await StorageService.saveItems(_items);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV Swipe'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'CSVインポート',
            onPressed: _importCsv,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset_status':
                  _resetStatuses();
                  break;
                case 'reset_all':
                  _resetAll();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset_status',
                child: Text('ステータスをリセット'),
              ),
              const PopupMenuItem(
                value: 'reset_all',
                child: Text('全データ削除'),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmptyState()
              : _tabIndex == 0
                  ? SwipeScreen(
                      items: _items,
                      onDataChanged: () => setState(() {}),
                    )
                  : ListScreen(
                      items: _items,
                      onDataChanged: () => setState(() {}),
                    ),
      bottomNavigationBar: _items.isEmpty
          ? null
          : BottomNavigationBar(
              currentIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.swipe),
                  label: 'スワイプ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: '一覧',
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.file_upload_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'CSVファイルをインポートして開始',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '1行目がヘッダーとして使用されます',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('CSVをインポート'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            onPressed: _importCsv,
          ),
        ],
      ),
    );
  }
}
