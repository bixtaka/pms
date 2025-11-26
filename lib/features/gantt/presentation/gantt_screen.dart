import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/project.dart';
import '../providers/gantt_providers.dart';
import '../widgets/gantt_chart.dart';

/// プロジェクト単位でガントチャートを表示する画面
class GanttScreen extends ConsumerWidget {
  final Project project;
  const GanttScreen({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(ganttItemsProvider(project.id));

    return Scaffold(
      appBar: AppBar(title: Text('ガントチャート - ${project.name}')),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (items) {
          final range = ref.read(dateRangeProvider(items));
          return GanttChart(
            items: items,
            dateRange: range,
            onBarTap: (item) {
              // TODO: 工程詳細画面へ遷移するなどの処理を追加可能
            },
          );
        },
      ),
    );
  }
}
