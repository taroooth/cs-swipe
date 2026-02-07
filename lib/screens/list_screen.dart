import 'package:flutter/material.dart';
import '../models/csv_item.dart';
import '../services/storage_service.dart';

class ListScreen extends StatefulWidget {
  final List<CsvItem> items;
  final VoidCallback onDataChanged;

  const ListScreen({
    super.key,
    required this.items,
    required this.onDataChanged,
  });

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  SwipeStatus _filter = SwipeStatus.ok;

  List<CsvItem> get _filteredItems =>
      widget.items.where((i) => i.status == _filter).toList();

  Color _statusColor(SwipeStatus status) {
    switch (status) {
      case SwipeStatus.ok:
        return Colors.green;
      case SwipeStatus.confirmed:
        return Colors.blue;
      case SwipeStatus.skipped:
        return Colors.orange;
      case SwipeStatus.unreviewed:
        return Colors.grey;
    }
  }

  int _countByStatus(SwipeStatus status) =>
      widget.items.where((i) => i.status == status).length;

  void _changeItemStatus(CsvItem item, SwipeStatus newStatus) async {
    item.status = newStatus;
    await StorageService.saveItems(widget.items);
    widget.onDataChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ステータスフィルタータブ
        Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SwipeStatus.values.where((s) => s != SwipeStatus.unreviewed).map((status) {
                final isSelected = _filter == status;
                final count = _countByStatus(status);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text('${status.label} ($count)'),
                    selectedColor: _statusColor(status).withOpacity(0.2),
                    checkmarkColor: _statusColor(status),
                    side: BorderSide(
                      color: isSelected
                          ? _statusColor(status)
                          : Colors.grey[300]!,
                    ),
                    onSelected: (_) {
                      setState(() => _filter = status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // 未レビュー数
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '未レビュー: ${_countByStatus(SwipeStatus.unreviewed)}件',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const Spacer(),
              Text(
                '合計: ${widget.items.length}件',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // リスト
        Expanded(
          child: _filteredItems.isEmpty
              ? Center(
                  child: Text(
                    '${_filter.label}のアイテムはありません',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return _buildItemTile(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildItemTile(CsvItem item) {
    final firstField = item.fields.entries.first;
    final subtitle = item.fields.entries.skip(1).take(2).map((e) => '${e.key}: ${e.value}').join(' / ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(item.status).withOpacity(0.15),
          child: Icon(
            _statusIcon(item.status),
            color: _statusColor(item.status),
            size: 20,
          ),
        ),
        title: Text(
          '${firstField.key}: ${firstField.value}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: PopupMenuButton<SwipeStatus>(
          icon: const Icon(Icons.more_vert),
          onSelected: (status) => _changeItemStatus(item, status),
          itemBuilder: (context) => SwipeStatus.values.map((status) {
            return PopupMenuItem(
              value: status,
              child: Row(
                children: [
                  Icon(_statusIcon(status), color: _statusColor(status), size: 18),
                  const SizedBox(width: 8),
                  Text(status.label),
                ],
              ),
            );
          }).toList(),
        ),
        onTap: () => _showDetail(item),
      ),
    );
  }

  IconData _statusIcon(SwipeStatus status) {
    switch (status) {
      case SwipeStatus.ok:
        return Icons.check_circle;
      case SwipeStatus.confirmed:
        return Icons.visibility;
      case SwipeStatus.skipped:
        return Icons.skip_next;
      case SwipeStatus.unreviewed:
        return Icons.radio_button_unchecked;
    }
  }

  void _showDetail(CsvItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ステータス変更ボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: SwipeStatus.values.map((status) {
                  final isActive = item.status == status;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(status.label),
                      selected: isActive,
                      selectedColor: _statusColor(status).withOpacity(0.2),
                      onSelected: (_) {
                        _changeItemStatus(item, status);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              ...item.fields.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          entry.value,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
