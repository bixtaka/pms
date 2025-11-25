import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gantt_providers.dart';
import '../widgets/gantt_chart.dart';

/// プロジェクト単位でガントチャートを表示する画面
class GanttScreen extends ConsumerWidget {
  final String projectId;
  final String projectName; // AppBar タイトル表示用
  const GanttScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(ganttItemsProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: Text('$projectName のガントチャート')),
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
