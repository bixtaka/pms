import 'package:flutter/material.dart';
import '../data/gantt_repository.dart';

/// 1 製品分の横バーを描画
class GanttRow extends StatelessWidget {
  final GanttItem item;
  final DateTime start;
  final DateTime end;
  final double dayWidth;
  final void Function(GanttItem item)? onTap;

  const GanttRow({
    super.key,
    required this.item,
    required this.start,
    required this.end,
    required this.dayWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rowHeight = 44.0;
    final barInfo = _calcBarPosition();

    return SizedBox(
      height: rowHeight,
      child: Stack(
        children: [
          // 背景のグリッド線
          Positioned.fill(
            child: Row(
              children: List.generate(
                end.difference(start).inDays + 1,
                (i) => Container(
                  width: dayWidth,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey.shade200,
                        width: 0.5,
                      ),
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 実際のバー
          Positioned(
            left: barInfo.left,
            top: 8,
            width: barInfo.width,
            height: rowHeight - 16,
            child: GestureDetector(
              onTap: onTap != null ? () => onTap!(item) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: _statusColor(itemStatus()),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// overallStartDate / overallEndDate から描画位置を計算
  _BarInfo _calcBarPosition() {
    final totalDays = end.difference(start).inDays + 1;
    final barStart = (item.overallStartDate ?? start).isBefore(start)
        ? start
        : DateTime(item.overallStartDate!.year, item.overallStartDate!.month,
            item.overallStartDate!.day);
    final barEnd = (item.overallEndDate ?? item.overallStartDate ?? start)
            .isAfter(end)
        ? end
        : DateTime(item.overallEndDate?.year ?? start.year,
            item.overallEndDate?.month ?? start.month,
            item.overallEndDate?.day ?? start.day);

    final offsetDays = barStart.difference(start).inDays;
    final lengthDays = (barEnd.difference(barStart).inDays + 1).clamp(1, totalDays);

    final left = offsetDays * dayWidth;
    final width = lengthDays * dayWidth;

    return _BarInfo(left: left, width: width);
  }

  String itemStatus() {
    // overallStatus がない場合は工程進捗の中から最も進んでいそうなステータスを推定
    // 簡易版として completed が一つでもあれば completed、それ以外に in_progress があれば in_progress、なければ not_started
    final progresses = item.processes.values;
    if (progresses.any((p) => p.status == 'completed')) return 'completed';
    if (progresses.any((p) => p.status == 'in_progress')) return 'in_progress';
    return 'not_started';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade400;
      case 'in_progress':
        return Colors.blue.shade400;
      case 'partial':
        return Colors.orange.shade300;
      default:
        return Colors.grey.shade400;
    }
  }
}

class _BarInfo {
  final double left;
  final double width;
  _BarInfo({required this.left, required this.width});
}
