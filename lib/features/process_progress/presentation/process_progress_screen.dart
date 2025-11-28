import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/process_master.dart';
import '../../../models/process_progress.dart';
import '../../../models/product.dart';
import '../../../providers/process_progress_providers.dart';
import '../../process_spec/data/process_progress_save_service.dart';
import 'daily_process_progress_screen.dart';

/// 製品ごとの工程一覧 + 進捗入力画面
/// - processMasters（対象の部材種 + COMMON）を取得
/// - 既存の processProgress をマージして表示
/// - ステータス / 開始日 / 終了日 / 備考を編集し、まとめて保存
class ProcessProgressScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String productId;
  final String? productCode;
  const ProcessProgressScreen({
    super.key,
    required this.projectId,
    required this.productId,
    this.productCode,
  });

  @override
  ConsumerState<ProcessProgressScreen> createState() =>
      _ProcessProgressScreenState();
}

class _ProcessProgressScreenState
    extends ConsumerState<ProcessProgressScreen> {
  // 編集中の工程進捗マップ: key = processId
  Map<String, ProcessProgress> _edited = {};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(
      productProvider(
        (projectId: widget.projectId, productId: widget.productId),
      ),
    );

    return productAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('エラー: $e'))),
      data: (product) {
        final mastersAsync =
            ref.watch(processMastersByMemberTypeProvider(product.memberType));
        final progressAsync = ref.watch(
          processProgressByProductProvider(
            (projectId: widget.projectId, productId: widget.productId),
          ),
        );

        return mastersAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(body: Center(child: Text('エラー: $e'))),
          data: (masters) => progressAsync.when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Scaffold(body: Center(child: Text('エラー: $e'))),
            data: (progressList) {
              _ensureInitialized(
                masters: masters,
                progressList: progressList,
                product: product,
              );

              final sortedMasters = [...masters]
                ..sort((a, b) {
                  final stage = a.stage.compareTo(b.stage);
                  if (stage != 0) return stage;
                  return a.orderInStage.compareTo(b.orderInStage);
                });

              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    '工程進捗: ${product.productCode.isNotEmpty ? product.productCode : (widget.productCode ?? '')}',
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      tooltip: '日別進捗入力',
                      onPressed: () {
                        // まず SnackBar で遷移することを通知
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('日別進捗入力画面を開きます'),
                          ),
                        );
                        // 対象工事・製品の 日別進捗入力画面 へ遷移
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DailyProcessProgressScreen(
                              projectId: widget.projectId,
                              productId: widget.productId,
                              productCode: product.productCode.isNotEmpty
                                  ? product.productCode
                                  : (widget.productCode ?? ''),
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: () => _saveAll(context),
                    ),
                  ],
                ),
                body: ListView.builder(
                  itemCount: sortedMasters.length,
                  itemBuilder: (_, i) {
                    final m = sortedMasters[i];
                    final pg = _edited[m.id]!;
                    return _ProcessRow(
                      master: m,
                      progress: pg,
                      onChanged: (updated) {
                        setState(() {
                          _edited[m.id] = updated;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 初期化: masters と progress をマージして _edited を作る
  void _ensureInitialized({
    required List<ProcessMaster> masters,
    required List<ProcessProgress> progressList,
    required Product product,
  }) {
    if (_initialized) return;
    final map = <String, ProcessProgress>{};
    final progressMap = {for (final p in progressList) p.processId: p};
    for (final m in masters) {
      final existing = progressMap[m.id];
      map[m.id] = existing ??
          ProcessProgress(
            processId: m.id,
            status: 'not_started',
            totalQuantity: product.quantity,
            completedQuantity: 0,
            startDate: null,
            endDate: null,
            remarks: '',
            updatedAt: null,
            updatedBy: '',
          );
    }
    _edited = map;
    _initialized = true;
  }

  Future<void> _saveAll(BuildContext context) async {
    final saveService = ProcessProgressSaveService();
    final messenger = ScaffoldMessenger.of(context);
    // 保存時は必ず日別 upsert を通し、同一 productId+stepId+date でレコードが増えないようにする
    try {
      for (final entry in _edited.entries) {
        final p = entry.value;
        final date = p.endDate ?? p.startDate ?? DateTime.now();
        await saveService.upsertDaily(
          projectId: widget.projectId,
          productId: widget.productId,
          stepId: p.processId,
          date: DateTime(date.year, date.month, date.day),
          doneQty: p.completedQuantity,
          note: p.remarks,
        );
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('保存しました')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    }
  }
}

/// 1工程分の編集 UI
class _ProcessRow extends StatelessWidget {
  final ProcessMaster master;
  final ProcessProgress progress;
  final ValueChanged<ProcessProgress> onChanged;

  const _ProcessRow({
    required this.master,
    required this.progress,
    required this.onChanged,
  });

  static const _statusOptions = [
    'not_started',
    'in_progress',
    'completed',
    'partial',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              master.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('ステージ: ${master.stage}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: progress.status,
                    decoration: const InputDecoration(labelText: 'ステータス'),
                    items: _statusOptions
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      onChanged(progress.copyWith(status: v));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _DateField(
                  label: '開始日',
                  value: progress.startDate,
                  onPicked: (date) =>
                      onChanged(progress.copyWith(startDate: date)),
                ),
                const SizedBox(width: 12),
                _DateField(
                  label: '終了日',
                  value: progress.endDate,
                  onPicked: (date) =>
                      onChanged(progress.copyWith(endDate: date)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: progress.remarks,
              decoration: const InputDecoration(labelText: '備考'),
              onChanged: (v) => onChanged(progress.copyWith(remarks: v)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 日付入力用ウィジェット
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPicked;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final text = value != null
        ? '${value!.year}/${value!.month}/${value!.day}'
        : '未設定';
    return Expanded(
      child: OutlinedButton(
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 5),
            lastDate: DateTime(now.year + 5),
          );
          onPicked(picked);
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('$label: $text'),
        ),
      ),
    );
  }
}
