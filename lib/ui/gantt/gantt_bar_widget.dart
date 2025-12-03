import 'package:flutter/material.dart';

import 'gantt_bar_models.dart';
import 'gantt_bar_painter.dart';

/// ガントバー描画用の薄いラッパーWidget。
class GanttBarWidget extends StatelessWidget {
  final GanttBar bar;
  final DateTime chartStart;
  final double dayWidth;

  const GanttBarWidget({
    super.key,
    required this.bar,
    required this.chartStart,
    required this.dayWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: bar.height,
      child: CustomPaint(
        painter: GanttBarPainter(
          bar: bar,
          chartStart: chartStart,
          dayWidth: dayWidth,
        ),
      ),
    );
  }
}
