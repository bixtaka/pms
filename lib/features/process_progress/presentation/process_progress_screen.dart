import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/process_progress_providers.dart';
import '../../../models/process_master.dart';
import '../../../models/process_progress.dart';
import '../../../models/product.dart';

/// 製品 × 工程の進捗画面
class ProcessProgressScreen extends ConsumerWidget {
  final String projectId;
  final String productId;
  const ProcessProgressScreen({
    super.key,
    required this.projectId,
    required this.productId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 製品取得
    final productAsync = ref.watch(
      productProvider((projectId: projectId, productId: productId)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('工程進捗')),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (product) => _ProcessProgressBody(
          projectId: projectId,
          product: product,
        ),
      ),
    );
  }
}

class _ProcessProgressBody extends ConsumerWidget {
  final String projectId;
  final Product product;
  const _ProcessProgressBody({
    required this.projectId,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ProcessMaster
    final mastersAsync =
        ref.watch(processMastersByMemberTypeProvider(product.memberType));
    // ProcessProgress
    final progressAsync = ref.watch(
      processProgressByProductProvider(
        (projectId: projectId, productId: product.id),
      ),
    );

    return mastersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (masters) {
        return progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (progressList) {
            // processId -> progress のマップを構築
            final progressMap = {
              for (final p in progressList) p.processId: p
            };
            // ステージ順 + orderInStage 順で表示
            final sortedMasters = [...masters]
              ..sort((a, b) {
                final s = a.stage.compareTo(b.stage);
                if (s != 0) return s;
                return a.orderInStage.compareTo(b.orderInStage);
              });

            return ListView.builder(
              itemCount: sortedMasters.length,
              itemBuilder: (_, i) {
                final m = sortedMasters[i];
                final pg = progressMap[m.id] ??
                    ProcessProgress(
                      processId: m.id,
                      status: 'not_started',
                      totalQuantity: product.quantity,
                      completedQuantity: 0,
                      updatedAt: null,
                      updatedBy: '',
                    );
                return _ProcessRow(
                  projectId: projectId,
                  productId: product.id,
                  productQuantity: product.quantity,
                  master: m,
                  progress: pg,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ProcessRow extends ConsumerWidget {
  final String projectId;
  final String productId;
  final int productQuantity;
  final ProcessMaster master;
  final ProcessProgress progress;
  const _ProcessRow({
    required this.projectId,
    required this.productId,
    required this.productQuantity,
    required this.master,
    required this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(processProgressRepoProvider);

    final ratio = progress.totalQuantity == 0
        ? 0.0
        : (progress.completedQuantity / progress.totalQuantity)
            .clamp(0, 1)
            .toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(master.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ステージ: ${master.stage}'),
            LinearProgressIndicator(value: ratio),
            Text(
              'status: ${progress.status}  ${progress.completedQuantity}/${progress.totalQuantity}',
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final newCompleted = progress.completedQuantity + 1;
            await repo.setProgress(
              projectId: projectId,
              productId: productId,
              progress: progress.copyWith(
                totalQuantity: productQuantity,
                completedQuantity: newCompleted,
                status: newCompleted >= productQuantity
                    ? 'completed'
                    : 'in_progress',
                updatedAt: DateTime.now(),
              ),
            );
          },
        ),
      ),
    );
  }
}
