import 'package:flutter/material.dart';

/// 日付ヘッダー（横スクロールと同期）
class GanttHeader extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final double dayWidth;
  final ScrollController controller;

  const GanttHeader({
    super.key,
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
