import 'package:flutter/material.dart';
import '../presentation/gantt_constants.dart';

/// ガントチャートの凡例Widget
class GanttLegend extends StatelessWidget {
  const GanttLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem(
            label: '計画',
            color: kGanttPlannedBarColor,
            height: 16,
          ),
          const SizedBox(width: 16),
          _legendItem(
            label: '進行中',
            color: kGanttActualInProgressColor,
            height: 10,
          ),
          const SizedBox(width: 16),
          _legendItem(
            label: '完了',
            color: kGanttActualDoneColor,
            height: 10,
          ),
          const SizedBox(width: 16),
          _todayLineItem(),
        ],
      ),
    );
  }

  Widget _legendItem({
    required String label,
    required Color color,
    required double height, // 高さも指定できるように
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _todayLineItem() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          '今日',
          style: TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}
