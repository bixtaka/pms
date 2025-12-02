import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product.dart';
import '../../../models/project.dart';
import '../../../providers/product_providers.dart';
import '../../process_spec/domain/process_progress_daily.dart';
import '../../process_spec/domain/process_step.dart';
import '../application/product_inspection_providers.dart';

enum InspectionStatus { notStarted, inProgress, done }

class ProductInspectionScreen extends ConsumerStatefulWidget {
  final Project project;
  final Product? initiallySelectedProduct;

  const ProductInspectionScreen({
    super.key,
    required this.project,
    this.initiallySelectedProduct,
  });

  @override
  ConsumerState<ProductInspectionScreen> createState() =>
      _ProductInspectionScreenState();
}

class _ProductInspectionScreenState
    extends ConsumerState<ProductInspectionScreen> {
  late final DateTime _today;
  String? _selectedProductId;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _selectedProductId = widget.initiallySelectedProduct?.id;
  }

  List<Product> _filterProducts(List<Product> products) {
    final kw = _keyword.trim().toLowerCase();
    if (kw.isEmpty) return products;
    return products.where((p) {
      final code = p.productCode.toLowerCase();
      final story = p.storyOrSet.toLowerCase();
      final grid = p.grid.toLowerCase();
      final section = p.section.toLowerCase();
      final name = p.name.toLowerCase();
      return code.contains(kw) ||
          story.contains(kw) ||
          grid.contains(kw) ||
          section.contains(kw) ||
          name.contains(kw);
    }).toList();
  }

  Product? _findProductById(List<Product> products, String? id) {
    if (id == null) return null;
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  InspectionStatus _statusFromQty(int doneQty, int quantity) {
    if (doneQty <= 0) return InspectionStatus.notStarted;
    if (quantity <= 0) return InspectionStatus.done;
    if (doneQty >= quantity) return InspectionStatus.done;
    return InspectionStatus.inProgress;
  }

  String _statusLabel(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.notStarted:
        return '未';
      case InspectionStatus.inProgress:
        return '作業中';
      case InspectionStatus.done:
        return '完了';
    }
  }

  Color _statusColor(BuildContext context, InspectionStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case InspectionStatus.notStarted:
        return scheme.outlineVariant;
      case InspectionStatus.inProgress:
        return scheme.secondary;
      case InspectionStatus.done:
        return scheme.primary;
    }
  }

  Future<void> _openFilterSheet() async {
    final controller = TextEditingController(text: _keyword);
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '製品フィルタ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '製品符号・節/通り芯・断面で検索',
                  prefixIcon: Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (v) => Navigator.of(ctx).pop(v),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(''),
                    child: const Text('クリア'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(controller.text),
                    child: const Text('適用'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      isScrollControlled: true,
    );
    controller.dispose();
    if (result != null) {
      setState(() {
        _keyword = result.trim();
      });
    }
  }

  ProcessProgressDaily? _findTodayForStep(
    List<ProcessProgressDaily> rows,
    String stepId,
  ) {
    for (final r in rows) {
      if (r.stepId == stepId) return r;
    }
    return null;
  }

  Future<void> _openEditSheet({
    required ProcessStep step,
    required Product product,
    required DailyProgressKey dailyKey,
    ProcessProgressDaily? existing,
  }) async {
    final repo = ref.read(processProgressDailyRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final maxQty = product.quantity > 0 ? product.quantity : 0;
    int doneQty = existing?.doneQty ?? 0;
    InspectionStatus status = _statusFromQty(doneQty, product.quantity);
    final qtyCtrl = TextEditingController(text: doneQty.toString());
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void updateStatus(InspectionStatus s) {
              setSheetState(() {
                status = s;
                if (s == InspectionStatus.notStarted) {
                  doneQty = 0;
                } else if (s == InspectionStatus.done) {
                  doneQty = maxQty > 0 ? maxQty : doneQty;
                }
                qtyCtrl.text = doneQty.toString();
              });
            }

            void updateQty(String value) {
              final parsed = int.tryParse(value) ?? 0;
              setSheetState(() {
                doneQty = parsed;
                status = _statusFromQty(doneQty, product.quantity);
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '工程: ${step.label}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('製品: ${product.productCode.isNotEmpty ? product.productCode : product.id}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(_statusLabel(InspectionStatus.notStarted)),
                        selected: status == InspectionStatus.notStarted,
                        onSelected: (_) => updateStatus(InspectionStatus.notStarted),
                      ),
                      if (maxQty > 1)
                        ChoiceChip(
                          label: Text(_statusLabel(InspectionStatus.inProgress)),
                          selected: status == InspectionStatus.inProgress,
                          onSelected: (_) =>
                              updateStatus(InspectionStatus.inProgress),
                        ),
                      ChoiceChip(
                        label: Text(_statusLabel(InspectionStatus.done)),
                        selected: status == InspectionStatus.done,
                        onSelected: (_) => updateStatus(InspectionStatus.done),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                '完了台数 (0〜${maxQty > 0 ? maxQty : '上限なし'})',
                          ),
                          onChanged: updateQty,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (product.quantity > 0)
                        Text('全体: ${product.quantity}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'コメント'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('キャンセル'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final parsed = int.tryParse(qtyCtrl.text) ?? 0;
                          final safeQty = parsed < 0
                              ? 0
                              : (maxQty > 0
                                  ? parsed.clamp(0, maxQty).toInt()
                                  : parsed);
                          try {
                            await repo.upsertDaily(
                              projectId: dailyKey.projectId,
                              productId: dailyKey.productId,
                              stepId: step.id,
                              date: dailyKey.dateOnly,
                              doneQty: safeQty,
                              note: noteCtrl.text.trim(),
                            );
                            ref.invalidate(
                              dailyProgressByProductProvider(dailyKey),
                            );
                            if (mounted) {
                              Navigator.of(ctx).pop();
                              messenger.showSnackBar(
                                const SnackBar(content: Text('保存しました')),
                              );
                            }
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('保存に失敗しました: $e'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    qtyCtrl.dispose();
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      productsByProjectProvider(widget.project.id),
    );
    final stepsAsync = ref.watch(inspectionProcessStepsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.project.name} / 製品別検査'),
        actions: [
          IconButton(
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.filter_list),
            tooltip: '製品フィルタ',
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('製品の読み込みに失敗しました: $e')),
        data: (products) {
          final filtered = _filterProducts(products);
          final selectedProduct = _findProductById(filtered, _selectedProductId) ??
              _findProductById(filtered, widget.initiallySelectedProduct?.id);

          return Row(
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _keyword.isEmpty
                                      ? '全製品'
                                      : 'フィルタ: $_keyword',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              IconButton(
                                onPressed: _openFilterSheet,
                                icon: const Icon(Icons.filter_alt),
                                tooltip: 'フィルタ',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (filtered.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('製品がありません'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 0),
                          itemBuilder: (_, index) {
                            final product = filtered[index];
                            final selected = product.id == _selectedProductId;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedProductId = product.id;
                                });
                              },
                              child: Container(
                                color: selected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.08)
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.productCode.isNotEmpty
                                          ? product.productCode
                                          : product.id,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selected
                                            ? Theme.of(context).colorScheme.primary
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (product.memberType.isNotEmpty)
                                          Chip(
                                            label: Text(product.memberType),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        if (product.storyOrSet.isNotEmpty)
                                          Chip(
                                            label: Text(product.storyOrSet),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        if (product.grid.isNotEmpty)
                                          Chip(
                                            label: Text(product.grid),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        if (product.section.isNotEmpty)
                                          Chip(
                                            label: Text(product.section),
                                            visualDensity: VisualDensity.compact,
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
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: selectedProduct == null
                    ? const Center(
                        child: Text('左のリストから製品を選択してください'),
                      )
                    : stepsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) =>
                            Center(child: Text('工程の取得に失敗しました: $e')),
                        data: (steps) {
                          final dailyKey = DailyProgressKey(
                            projectId: widget.project.id,
                            productId: selectedProduct.id,
                            date: _today,
                          );
                          final dailyAsync =
                              ref.watch(dailyProgressByProductProvider(dailyKey));
                          return dailyAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) =>
                                Center(child: Text('進捗の取得に失敗しました: $e')),
                            data: (daily) => _StepList(
                              steps: steps,
                              daily: daily,
                              product: selectedProduct,
                              statusLabel: _statusLabel,
                              statusColor: _statusColor,
                              statusFromQty: _statusFromQty,
                              findTodayForStep: _findTodayForStep,
                              onEdit: (step, existing) => _openEditSheet(
                                step: step,
                                product: selectedProduct,
                                dailyKey: dailyKey,
                                existing: existing,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  final List<ProcessStep> steps;
  final List<ProcessProgressDaily> daily;
  final Product product;
  final String Function(InspectionStatus) statusLabel;
  final Color Function(BuildContext, InspectionStatus) statusColor;
  final InspectionStatus Function(int, int) statusFromQty;
  final ProcessProgressDaily? Function(List<ProcessProgressDaily>, String)
      findTodayForStep;
  final void Function(ProcessStep, ProcessProgressDaily?) onEdit;

  const _StepList({
    required this.steps,
    required this.daily,
    required this.product,
    required this.statusLabel,
    required this.statusColor,
    required this.statusFromQty,
    required this.findTodayForStep,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const Center(child: Text('工程が登録されていません'));
    }
    final sorted = List<ProcessStep>.from(steps)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            border: const Border(
              bottom: BorderSide(color: Colors.black12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productCode.isNotEmpty
                    ? product.productCode
                    : product.id,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (product.memberType.isNotEmpty)
                    Chip(
                      label: Text(product.memberType),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (product.storyOrSet.isNotEmpty)
                    Chip(
                      label: Text(product.storyOrSet),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (product.grid.isNotEmpty)
                    Chip(
                      label: Text(product.grid),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (product.section.isNotEmpty)
                    Chip(
                      label: Text(product.section),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final step = sorted[index];
              final today = findTodayForStep(daily, step.id);
              final doneQty = today?.doneQty ?? 0;
              final status = statusFromQty(doneQty, product.quantity);
              final chipColor = statusColor(context, status);
              final chipTextColor = status == InspectionStatus.notStarted
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.white;
              final subtitle = <String>[
                'キー: ${step.key}',
                '今日: $doneQty 台'
              ];
              if (today?.note.isNotEmpty == true) {
                subtitle.add('メモ: ${today!.note}');
              }

              return Card(
                child: ListTile(
                  title: Text(step.label),
                  subtitle: Text(subtitle.join(' / ')),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(
                          statusLabel(status),
                          style: TextStyle(color: chipTextColor),
                        ),
                        backgroundColor: chipColor,
                      ),
                      if (product.quantity > 0)
                        Text(
                          '数量: ${product.quantity}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                  onTap: () => onEdit(step, today),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
