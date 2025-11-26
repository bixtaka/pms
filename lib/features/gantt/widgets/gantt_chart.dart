import 'package:flutter/material.dart';
import '../data/gantt_repository.dart';

/// ガントチャート全体を描画するウィジェット
/// - 左カラムに productCode（幅120）
/// - 日付ヘッダーは月/日表示で横スクロール
/// - 1日=24px のグリッド
/// - overallStartDate/overallEndDate が null の場合でも安全に描画する
class GanttChart extends StatelessWidget {
  final List<GanttItem> items;
  final DateTimeRange dateRange;
  final double dayWidth;
  final void Function(GanttItem item)? onBarTap;

  const GanttChart({
    super.key,
    required this.items,
    required this.dateRange,
    this.dayWidth = 24.0,
    this.onBarTap,
  });

  @override
  Widget build(BuildContext context) {
    // ヘッダーとボディの横スクロールを同期させるコントローラ
    final scrollController = ScrollController();

    return Column(
      children: [
        _GanttHeader(
          start: dateRange.start,
          end: dateRange.end,
          dayWidth: dayWidth,
          controller: scrollController,
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              // 左カラム: 製品コードを固定幅で表示
              SizedBox(
                width: 120,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Text(
                      items[i].productCode,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              // 右側: ガントバー領域（横スクロール）
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _chartWidth(),
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) => _GanttRow(
                        item: items[i],
                        start: dateRange.start,
                        end: dateRange.end,
                        dayWidth: dayWidth,
                        onTap: onBarTap,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _chartWidth() {
    final days = dateRange.end.difference(dateRange.start).inDays + 1; // inclusive
    return days * dayWidth;
  }
}

/// 日付ヘッダー
class _GanttHeader extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final double dayWidth;
  final ScrollController controller;

  const _GanttHeader({
    required this.start,
    required this.end,
    required this.dayWidth,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final days = end.difference(start).inDays + 1;
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(days, (index) {
            final date = start.add(Duration(days: index));
            return Container(
              width: dayWidth,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${date.month}/${date.day}',
                style: const TextStyle(fontSize: 12),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// 1 行（1 製品分）のガントバーを描画
class _GanttRow extends StatelessWidget {
  final GanttItem item;
  final DateTime start;
  final DateTime end;
  final double dayWidth;
  final void Function(GanttItem item)? onTap;

  const _GanttRow({
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
          // 背景グリッド
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
          // 実際のバー（null 安全な位置計算後）
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

  /// overallStartDate / overallEndDate が null の場合も安全にバー位置を計算
  _BarInfo _calcBarPosition() {
    // 1. null の扱い
    //    - 両方 null: start = dateRange.start, end = start (1日ダミー)
    //    - start null: dateRange.start
    //    - end null: end = start
    final safeStart = item.overallStartDate ?? start;
    final safeEnd = item.overallEndDate ?? item.overallStartDate ?? start;

    // 2. end < start の場合は end = start にクランプ
    final clampedEnd = safeEnd.isBefore(safeStart) ? safeStart : safeEnd;

    // 3. 表示範囲にクランプ
    final rangeStart = start;
    final rangeEnd = end;
    final startClamped =
        safeStart.isBefore(rangeStart) ? rangeStart : safeStart;
    final endClamped = clampedEnd.isAfter(rangeEnd) ? rangeEnd : clampedEnd;

    // 4. 日数計算（1日以上にする）
    final offsetDays = startClamped.difference(rangeStart).inDays;
    final lengthDays =
        (endClamped.difference(startClamped).inDays + 1).clamp(1, 9999);

    final left = offsetDays * dayWidth;
    final width = lengthDays * dayWidth;

    return _BarInfo(left: left, width: width);
  }

  /// overallStatus があればそれを優先、なければ工程進捗から推定
  String itemStatus() {
    final progresses = item.processes.values;
    if (progresses.any((p) => p.status == 'completed')) return 'completed';
    if (progresses.any((p) => p.status == 'in_progress')) return 'in_progress';
    if (progresses.any((p) => p.status == 'partial')) return 'partial';
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
      case 'not_started':
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
