import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gantt_repository.dart';

/// フィルタ条件（必要に応じて拡張）
class GanttFilter {
  final String? memberType;
  final String? status;
  const GanttFilter({this.memberType, this.status});
}

// リポジトリプロバイダ
final ganttRepositoryProvider = Provider<GanttRepository>((ref) {
  return GanttRepository();
});

// ガントアイテム取得
final ganttItemsProvider =
    FutureProvider.family<List<GanttItem>, String>((ref, projectId) async {
  final repo = ref.watch(ganttRepositoryProvider);
  return repo.fetchGanttItems(projectId);
});

// 日付範囲算出
final dateRangeProvider =
    Provider.family<DateTimeRange, List<GanttItem>>((ref, items) {
  final repo = ref.watch(ganttRepositoryProvider);
  return repo.computeDateRange(items);
});

// フィルタ適用（任意で memberType / status を絞り込み）
final filteredGanttItemsProvider = FutureProvider.family<
    List<GanttItem>,
    ({String projectId, GanttFilter? filter})>((ref, params) async {
  final items = await ref.watch(ganttItemsProvider(params.projectId).future);
  final f = params.filter;
  if (f == null) return items;
  return items.where((item) {
    final matchMember = f.memberType == null ||
        (item.processes.values.any((p) => p.status == f.status) ||
            true); // memberType は Product に持たせていないので必要なら拡張
    final matchStatus = f.status == null ||
        item.processes.values.any((p) => p.status == f.status);
    return matchMember && matchStatus;
  }).toList();
});
