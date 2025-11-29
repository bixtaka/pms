import 'package:flutter/material.dart';

import '../../process_spec/data/process_progress_daily_repository.dart';
import '../../process_spec/data/process_steps_repository.dart';
import '../../process_spec/domain/process_step.dart';

/// SPEC.md に準拠した 1製品×1日分の「日別進捗入力」画面。
/// - 対象: projectId + productId + 指定日
/// - 行: process_steps（現状は process_groups からの擬似 step）
/// - 入力: doneQty(int), note(String)
/// - 保存: ProcessProgressDailyRepository.upsertDaily(...) を必ず使用し、
///         同一 (productId, stepId, date) でレコードが増えないようにする。
class DailyProcessProgressScreen extends StatefulWidget {
  final String projectId;
  final String productId;
  final String? productCode;

  const DailyProcessProgressScreen({
    super.key,
    required this.projectId,
    required this.productId,
    this.productCode,
  });

  @override
  State<DailyProcessProgressScreen> createState() =>
      _DailyProcessProgressScreenState();
}

class _DailyProcessProgressScreenState
    extends State<DailyProcessProgressScreen> {
  final ProcessStepsRepository _stepsRepo = ProcessStepsRepository();
  final ProcessProgressDailyRepository _dailyRepo =
      ProcessProgressDailyRepository();

  // 選択中の日付（年月日のみ保持）
  late DateTime _selectedDate;

  bool _loading = true;
  List<ProcessStep> _steps = <ProcessStep>[];

  // stepId ごとの入力コントローラ
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _noteControllers = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    // 工程一覧は SPEC の process_steps（現状は groups からの擬似 step）
    final steps = await _stepsRepo.fetchAll();

    // 対象製品の全日別進捗を取得し、選択日のみ抽出
    final allDaily = await _dailyRepo.fetchDaily(
      widget.projectId,
      widget.productId,
    );
    final sameDayRows = allDaily
        .where(
          (d) =>
              d.date.year == _selectedDate.year &&
              d.date.month == _selectedDate.month &&
              d.date.day == _selectedDate.day,
        )
        .toList();
    final byStep = {
      for (final d in sameDayRows) d.stepId: d,
    };

    // 各工程ごとに初期値をコントローラへ反映
    for (final step in steps) {
      final existing = byStep[step.id];

      final qtyController =
          _qtyControllers[step.id] ?? TextEditingController();
      qtyController.text = (existing?.doneQty ?? 0).toString();
      _qtyControllers[step.id] = qtyController;

      final noteController =
          _noteControllers[step.id] ?? TextEditingController();
      noteController.text = existing?.note ?? '';
      _noteControllers[step.id] = noteController;
    }

    setState(() {
      _steps = steps;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    final only = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      _selectedDate = only;
    });
    await _loadData();
  }

  Future<void> _saveAll() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      for (final step in _steps) {
        final qtyText = _qtyControllers[step.id]?.text ?? '0';
        final noteText = _noteControllers[step.id]?.text ?? '';
        final doneQty = int.tryParse(qtyText) ?? 0;

        await _dailyRepo.upsertDaily(
          projectId: widget.projectId,
          productId: widget.productId,
          stepId: step.id,
          date: _selectedDate,
          doneQty: doneQty,
          note: noteText,
        );
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('保存しました')),
      );
    } on StateError catch (e) {
      // 未来日など、仕様上禁止されている入力
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final titleProductCode = widget.productCode ?? widget.productId;

    return Scaffold(
      appBar: AppBar(
        title: Text('日別進捗入力 - $titleProductCode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _loading ? null : _saveAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '工事ID: ${widget.projectId}\n製品ID: ${widget.productId}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_formatDate(_selectedDate)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      final qtyController = _qtyControllers[step.id]!;
                      final noteController = _noteControllers[step.id]!;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: qtyController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: '完了台数',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: noteController,
                                      decoration: const InputDecoration(
                                        labelText: 'メモ',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

