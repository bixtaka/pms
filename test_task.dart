import 'package:legacy_gantt_chart/legacy_gantt_chart.dart';

void main() {
  final t = LegacyGanttTask(
    id: '1',
    rowId: '1',
    name: 't',
    start: DateTime.now(),
    end: DateTime.now(),
    progress: 0.5,
    baselineStart: DateTime.now(),
    baselineEnd: DateTime.now(),
  );
  print(t.baselineStart);
}
