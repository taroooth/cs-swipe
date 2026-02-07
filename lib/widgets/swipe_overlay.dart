import 'package:flutter/material.dart';

class SwipeOverlay extends StatelessWidget {
  final Offset offset;

  const SwipeOverlay({super.key, required this.offset});

  @override
  Widget build(BuildContext context) {
    final dx = offset.dx;
    final dy = offset.dy;
    final threshold = 40.0;

    String? label;
    Color? color;

    if (dy < -threshold && dy.abs() > dx.abs()) {
      label = 'スキップ';
      color = Colors.orange;
    } else if (dx > threshold) {
      label = '確認';
      color = Colors.blue;
    } else if (dx < -threshold) {
      label = 'OK';
      color = Colors.green;
    }

    if (label == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color!, width: 4),
        ),
        child: Center(
          child: Transform.rotate(
            angle: -0.2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
