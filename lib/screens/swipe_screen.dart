import 'package:flutter/material.dart';
import '../models/csv_item.dart';
import '../services/storage_service.dart';
import '../widgets/swipe_card.dart';
import '../widgets/swipe_overlay.dart';

class SwipeScreen extends StatefulWidget {
  final List<CsvItem> items;
  final VoidCallback onDataChanged;

  const SwipeScreen({
    super.key,
    required this.items,
    required this.onDataChanged,
  });

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  late AnimationController _animController;
  late Animation<Offset> _animOffset;
  bool _isAnimating = false;

  List<CsvItem> get _unreviewedItems =>
      widget.items.where((i) => i.status == SwipeStatus.unreviewed).toList();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _dragOffset = Offset.zero;
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;
    final threshold = 100.0;

    SwipeStatus? newStatus;
    Offset flyAway;

    if (dy < -threshold && dy.abs() > dx.abs()) {
      newStatus = SwipeStatus.skipped;
      flyAway = Offset(0, -800);
    } else if (dx > threshold) {
      newStatus = SwipeStatus.confirmed;
      flyAway = Offset(500, 0);
    } else if (dx < -threshold) {
      newStatus = SwipeStatus.ok;
      flyAway = Offset(-500, 0);
    } else {
      // しきい値未満：元に戻す
      _animateBack();
      return;
    }

    _animateOut(flyAway, newStatus);
  }

  void _animateBack() {
    _isAnimating = true;
    _animOffset = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.reset();
    _animController.forward();
    _animOffset.addListener(() {
      setState(() {
        _dragOffset = _animOffset.value;
      });
    });
  }

  void _animateOut(Offset target, SwipeStatus status) {
    _isAnimating = true;
    final items = _unreviewedItems;
    if (items.isEmpty) return;

    final item = items[_currentIndex % items.length];

    _animOffset = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    ));

    _animController.reset();
    _animController.forward().then((_) {
      item.status = status;
      StorageService.saveItems(widget.items);
      widget.onDataChanged();
      setState(() {
        _dragOffset = Offset.zero;
        _isAnimating = false;
        // インデックスが範囲外にならないように調整
        final remaining = _unreviewedItems;
        if (remaining.isNotEmpty) {
          _currentIndex = _currentIndex % remaining.length;
        }
      });
    });

    _animOffset.addListener(() {
      setState(() {
        _dragOffset = _animOffset.value;
      });
    });
  }

  void _undoLast() async {
    // 直前にレビュー済みにしたアイテムを戻す
    final reviewed = widget.items
        .where((i) => i.status != SwipeStatus.unreviewed)
        .toList();
    if (reviewed.isEmpty) return;

    final last = reviewed.last;
    last.status = SwipeStatus.unreviewed;
    await StorageService.saveItems(widget.items);
    widget.onDataChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = _unreviewedItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
            const SizedBox(height: 16),
            const Text(
              '全てレビュー済みです',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '一覧タブでステータスを確認できます',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final safeIndex = _currentIndex % items.length;
    final currentItem = items[safeIndex];

    return Column(
      children: [
        // スワイプヒント
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _hintChip('← OK', Colors.green),
              _hintChip('↑ スキップ', Colors.orange),
              _hintChip('確認 →', Colors.blue),
            ],
          ),
        ),
        // カード
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Transform.translate(
                offset: _dragOffset,
                child: Transform.rotate(
                  angle: _dragOffset.dx * 0.001,
                  child: Stack(
                    children: [
                      SwipeCard(
                        item: currentItem,
                        currentIndex: safeIndex,
                        totalCount: items.length,
                      ),
                      SwipeOverlay(offset: _dragOffset),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // ボタン
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(
                icon: Icons.check,
                label: 'OK',
                color: Colors.green,
                onTap: () => _animateOut(Offset(-500, 0), SwipeStatus.ok),
              ),
              _actionButton(
                icon: Icons.undo,
                label: '戻す',
                color: Colors.grey,
                onTap: _undoLast,
              ),
              _actionButton(
                icon: Icons.skip_next,
                label: 'スキップ',
                color: Colors.orange,
                onTap: () => _animateOut(Offset(0, -800), SwipeStatus.skipped),
              ),
              _actionButton(
                icon: Icons.visibility,
                label: '確認',
                color: Colors.blue,
                onTap: () => _animateOut(Offset(500, 0), SwipeStatus.confirmed),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hintChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
