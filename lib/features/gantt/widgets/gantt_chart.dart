import 'package:flutter/material.dart';
import '../data/gantt_repository.dart';
import 'gantt_header.dart';
import 'gantt_row.dart';

/// 全体のガントチャートを構成するウィジェット
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
    // ヘッダーとボディを横スクロールで揃えるため、ScrollControllerを共有する
    final scrollController = ScrollController();

    return Column(
      children: [
        // 日付ヘッダー
        GanttHeader(
          start: dateRange.start,
          end: dateRange.end,
          dayWidth: dayWidth,
          controller: scrollController,
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              // 製品コードラベル用の固定幅カラム
              SizedBox(
                width: 140,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
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
              // ガントバー部分（横スクロール）
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _chartWidth(),
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) => GanttRow(
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
    final days =
        dateRange.end.difference(dateRange.start).inDays + 1; // inclusive
    return days * dayWidth;
  }
}
