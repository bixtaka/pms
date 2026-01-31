import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../presentation/gantt_constants.dart';
import '../presentation/gantt_utils.dart';

/// ガントチャートのタイムラインヘッダー（月行+日行）
///
/// スクロール同期とドラッグ操作をサポート。
class GanttTimelineHeader extends StatelessWidget {
  final int daysCount;
  final DateTime startDate;
  final double dayWidth;
  final ScrollController headerController;
  final ScrollController mainController;
  final double Function(ScrollController) computeHeaderDragScale;
  final String Function(DateTime date, int index) dayHeaderLabel;
  final List<Widget> Function(BuildContext, List<DateTime>, DayCellBuilder) buildDayCells;

  const GanttTimelineHeader({
    super.key,
    required this.daysCount,
    required this.startDate,
    required this.dayWidth,
    required this.headerController,
    required this.mainController,
    required this.computeHeaderDragScale,
    required this.dayHeaderLabel,
    required this.buildDayCells,
  });

  @override
  Widget build(BuildContext context) {
    final dates = List<DateTime>.generate(
      daysCount,
      (i) => startDate.add(Duration(days: i)),
    );

    final totalWidth = daysCount * dayWidth;
    final headerHeight = kTimelineMonthRowHeight + kTimelineDayRowHeight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onHorizontalDragUpdate: (details) {
        if (!mainController.hasClients) return;

        final double scale = computeHeaderDragScale(mainController);
        final double delta = details.delta.dx * scale;
        final double maxScroll = mainController.position.maxScrollExtent;
        final double oldOffset = mainController.offset;
        final double newOffset = (oldOffset - delta).clamp(0.0, maxScroll);
        mainController.jumpTo(newOffset);
      },
      child: SizedBox(
        height: headerHeight,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          controller: headerController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMonthHeaderRow(dates),
                _buildDayHeaderRow(context, dates),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeaderRow(List<DateTime> dates) {
    if (dates.isEmpty) {
      return SizedBox(height: kTimelineMonthRowHeight);
    }

    final List<MonthSpan> spans = [];
    int currentMonth = dates.first.month;
    int startIndex = 0;

    for (var i = 1; i < dates.length; i++) {
      final date = dates[i];
      if (date.month != currentMonth) {
        spans.add(
          MonthSpan(
            month: currentMonth,
            startIndex: startIndex,
            endIndex: i - 1,
          ),
        );
        currentMonth = date.month;
        startIndex = i;
      }
    }
    spans.add(
      MonthSpan(
        month: currentMonth,
        startIndex: startIndex,
        endIndex: dates.length - 1,
      ),
    );

    return SizedBox(
      height: kTimelineMonthRowHeight,
      child: Row(
        children: spans.map((span) {
          final monthDate = dates[span.startIndex];
          return SizedBox(
            width: span.length * dayWidth,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${monthDate.month}',
                textAlign: TextAlign.center,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayHeaderRow(BuildContext context, List<DateTime> dates) {
    return Row(
      children: buildDayCells(
        context,
        dates,
        (context, date, index) {
          final label = dayHeaderLabel(date, index);
          return Container(
            height: kTimelineDayRowHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          );
        },
      ),
    );
  }
}
