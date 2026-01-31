import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/product.dart';
import '../../../models/project.dart';
import '../../../providers/product_providers.dart';
import '../../process_spec/domain/process_progress_daily.dart';
import '../../process_spec/domain/process_group.dart';
import '../../process_spec/domain/process_step.dart';
import '../application/product_inspection_providers.dart';
import '../../process_spec/data/process_progress_save_service.dart';
import '../../gantt/presentation/gantt_screen.dart';
import '../../inspection/data/annotation_storage_service.dart';
import 'package:flutter/foundation.dart';

enum InspectionStatus { notStarted, inProgress, done }

InspectionStatus statusFromDailyRecord(ProcessProgressDaily? record) {
  if (record == null) {
    return InspectionStatus.notStarted;
  }
  if (record.doneQty <= 0) {
    return InspectionStatus.inProgress;
  }
  return InspectionStatus.done;
}

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

  String _memberTypePrefix(String memberType) {
    switch (memberType.toLowerCase()) {
      case 'column':
        return 'column_';
      case 'girder':
        return 'girder_';
      case 'beam':
        return 'beam_';
      case 'intermediate':
        return 'intermediate_';
      default:
        return '';
    }
  }

  List<ProcessStep> _filterStepsByMemberType(
    List<ProcessStep> steps,
    String memberType,
  ) {
    final prefix = _memberTypePrefix(memberType);
    if (prefix.isEmpty) return steps;
    return steps.where((s) => s.id.startsWith(prefix)).toList();
  }

  List<_UiProcessStep> _buildUiSteps(
    List<ProcessStep> steps,
    List<ProcessGroup> groups,
  ) {
    final sortedGroups = List<ProcessGroup>.from(groups)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final uiSteps = <_UiProcessStep>[];
    for (final g in sortedGroups) {
      final groupSteps = steps
          .where((s) => s.groupId == g.id)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final s in groupSteps) {
        uiSteps.add(_UiProcessStep(group: g, step: s));
      }
    }

    // グループが見つからなかった工程を最後に並べる（安定化）
    final groupedIds = sortedGroups.map((g) => g.id).toSet();
    final orphanSteps = steps
        .where((s) => !groupedIds.contains(s.groupId))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final s in orphanSteps) {
      uiSteps.add(_UiProcessStep(group: null, step: s));
    }

    return uiSteps;
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
    final saveService = ProcessProgressSaveService();
    final messenger = ScaffoldMessenger.of(context);
    final maxQty = product.quantity > 0 ? product.quantity : 0;
    int doneQty = existing?.doneQty ?? 0;
    InspectionStatus status = statusFromDailyRecord(existing);
    final qtyCtrl = TextEditingController(text: doneQty.toString());
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // For custom rounded corners
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void updateStatus(InspectionStatus s) {
              setSheetState(() {
                status = s;
                if (s == InspectionStatus.notStarted) {
                  doneQty = 0;
                } else if (s == InspectionStatus.inProgress) {
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

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                             product.productCode.isNotEmpty ? product.productCode : product.id,
                             style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey2, size: 28),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Segmented Control
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<InspectionStatus>(
                      groupValue: status,
                      children: const {
                        InspectionStatus.notStarted: Padding(padding: EdgeInsets.all(8), child: Text('未着手')),
                        InspectionStatus.inProgress: Padding(padding: EdgeInsets.all(8), child: Text('作業中')),
                        InspectionStatus.done: Padding(padding: EdgeInsets.all(8), child: Text('完了')),
                      },
                      onValueChanged: (v) {
                        if (v != null) updateStatus(v);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quantity Input
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '完了台数',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CupertinoTextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onChanged: updateQty,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (maxQty > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '全体',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$maxQty',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Note Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'コメント',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CupertinoTextField(
                        controller: noteCtrl,
                        maxLines: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () async {
                          final parsed = int.tryParse(qtyCtrl.text) ?? 0;
                          final safeQty = parsed < 0
                              ? 0
                              : (maxQty > 0
                                  ? parsed.clamp(0, maxQty).toInt()
                                  : parsed);
                          try {
                            if (status == InspectionStatus.notStarted) {
                              await saveService.deleteDaily(
                                projectId: dailyKey.projectId,
                                productId: dailyKey.productId,
                                stepId: step.id,
                                date: dailyKey.dateOnly,
                              );
                            } else {
                              await saveService.upsertDaily(
                                projectId: dailyKey.projectId,
                                productId: dailyKey.productId,
                                stepId: step.id,
                                date: dailyKey.dateOnly,
                                doneQty: safeQty,
                                note: noteCtrl.text.trim(),
                              );
                            }
                            ref.invalidate(
                              dailyProgressByProductProvider(dailyKey),
                            );
                            if (mounted) {
                              Navigator.of(ctx).pop();
                              // Simple iOS style feedback? Or Keep Snackbar for consistency
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('保存しました')),
                              );
                            }
                          } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('保存に失敗しました: $e')),
                              );
                          }
                      },
                      child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
    final groupsAsync = ref.watch(inspectionProcessGroupsProvider);
    final stepsAsync = ref.watch(inspectionProcessStepsProvider);

          return Scaffold(
            backgroundColor: const Color(0xFFF2F2F7), // systemGroupedBackground
            appBar: AppBar(
              backgroundColor: const Color(0xFFF2F2F7),
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: false,
              title: Text(
                '${widget.project.name} / 製品別検査',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              actions: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.search, size: 24),
                  onPressed: _openFilterSheet,
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('製品の読み込みに失敗しました: $e')),
              data: (products) {
                final selectedIds = ref.watch(inspectionSelectedProductIdsProvider);
                var filtered = _filterProducts(products);
                if (selectedIds.isNotEmpty) {
                  filtered = filtered.where((p) => selectedIds.contains(p.id)).toList();
                }
                final selectedProduct = _findProductById(filtered, _selectedProductId) ??
                    _findProductById(filtered, widget.initiallySelectedProduct?.id);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 350, // Slightly wider for card layout
                      child: Column(
                        children: [
                          if (kDebugMode)
                            Container(
                              width: double.infinity,
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Text(
                                'selected=${selectedIds.length} total=${products.length} shown=${filtered.length}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
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
                    if (filtered.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            selectedIds.isEmpty
                                ? '検査入力で製品を選択してください'
                                : '選択中の製品がありません',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            final product = filtered[index];
                            final selected = product.id == _selectedProductId;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedProductId = product.id;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: selected
                                      ? Border.all(
                                          color: CupertinoColors.systemBlue,
                                          width: 2,
                                        )
                                      : Border.all(
                                          color: Colors.transparent,
                                          width: 2,
                                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Drawing Thumbnail
                                    _ProductDrawingThumbnail(
                                      productCode: product.id, // Use product.id for Storage path
                                    ),
                                    const SizedBox(width: 12),
                                    // Product Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.productCode.isNotEmpty
                                                ? product.productCode
                                                : product.id,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: selected
                                                  ? CupertinoColors.systemBlue
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              if (product.memberType.isNotEmpty)
                                                _TagChip(label: product.memberType),
                                              if (product.storyOrSet.isNotEmpty)
                                                _TagChip(label: product.storyOrSet),
                                              if (product.grid.isNotEmpty)
                                                _TagChip(label: product.grid),
                                              if (product.section.isNotEmpty)
                                                _TagChip(label: product.section),
                                            ],
                                          ),
                                        ],
                                      ),
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
              // Use spacing instead of divider
              const SizedBox(width: 1),
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
                        data: (steps) => groupsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) =>
                              Center(child: Text('工程グループ取得に失敗しました: $e')),
                          data: (groups) {
                            final filteredSteps = _filterStepsByMemberType(
                              steps,
                              selectedProduct.memberType,
                            );
                            final uiSteps = _buildUiSteps(filteredSteps, groups);
                            final dailyKey = DailyProgressKey(
                              projectId: widget.project.id,
                              productId: selectedProduct.id,
                              date: _today,
                            );
                            final dailyAsync = ref.watch(
                              dailyProgressByProductProvider(dailyKey),
                            );
                            return dailyAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) =>
                                  Center(child: Text('進捗の取得に失敗しました: $e')),
                              data: (daily) => _StepList(
                                steps: uiSteps,
                                daily: daily,
                                product: selectedProduct,
                                statusLabel: _statusLabel,
                                statusColor: _statusColor,
                                statusFromQty: _statusFromQty,
                                findTodayForStep: _findTodayForStep,
                                onEdit: (uiStep, existing) => _openEditSheet(
                                  step: uiStep.step,
                                  product: selectedProduct,
                                  dailyKey: dailyKey,
                                  existing: existing,
                                ),
                              ),
                            );
                          },
                        ),
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
  final List<_UiProcessStep> steps;
  final List<ProcessProgressDaily> daily;
  final Product product;
  final String Function(InspectionStatus) statusLabel;
  final Color Function(BuildContext, InspectionStatus) statusColor;
  final InspectionStatus Function(int, int) statusFromQty;
  final ProcessProgressDaily? Function(List<ProcessProgressDaily>, String)
      findTodayForStep;
  final void Function(_UiProcessStep, ProcessProgressDaily?) onEdit;

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
      return const Center(child: Text('工程が登録されていません', style: TextStyle(color: Colors.grey)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E5EA)), // systemSeparator
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
                  fontSize: 22, // Larger title
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (product.memberType.isNotEmpty) _TagChip(label: product.memberType),
                  if (product.storyOrSet.isNotEmpty) _TagChip(label: product.storyOrSet),
                  if (product.grid.isNotEmpty) _TagChip(label: product.grid),
                  if (product.section.isNotEmpty) _TagChip(label: product.section),
                ],
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: steps.length,
            itemBuilder: (_, index) {
              final uiStep = steps[index];
              final step = uiStep.step;
              final today = findTodayForStep(daily, step.id);
              final status = statusFromDailyRecord(today);
              
              // Status Badge Color
              final Color badgeColor = switch(status) {
                InspectionStatus.done => CupertinoColors.systemGreen,
                InspectionStatus.inProgress => CupertinoColors.systemOrange,
                InspectionStatus.notStarted => CupertinoColors.systemGrey4,
              };
              final Color badgeText = status == InspectionStatus.notStarted ? Colors.black87 : Colors.white;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => onEdit(uiStep, today),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Main Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uiStep.displayLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (today != null && today.doneQty > 0)
                                Text(
                                  '今日: ${today.doneQty} 台',
                                  style: TextStyle(
                                    fontSize: 13, 
                                    color: Colors.grey.shade600
                                  ),
                                ),
                              if (today?.note.isNotEmpty == true)
                                Text(
                                  'メモ: ${today!.note}',
                                  style: TextStyle(
                                    fontSize: 13, 
                                    color: Colors.grey.shade600
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel(status),
                            style: TextStyle(
                              color: badgeText,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: CupertinoColors.systemGrey3,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UiProcessStep {
  final ProcessGroup? group;
  final ProcessStep step;

  const _UiProcessStep({required this.group, required this.step});

  String get displayLabel {
    final prefix =
        group != null && group!.label.isNotEmpty ? '${group!.label} ' : '';
    return '$prefix${step.label}';
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA), // systemFill
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }
}

/// 製品リスト用の図面サムネイル
/// 
/// Firebase Storage から `products/{productCode}/drawing.png` を取得して表示
/// 読み込み中は Shimmer、画像がない場合はドキュメントアイコンを表示
class _ProductDrawingThumbnail extends StatefulWidget {
  const _ProductDrawingThumbnail({required this.productCode});
  
  final String productCode;

  @override
  State<_ProductDrawingThumbnail> createState() => _ProductDrawingThumbnailState();
}

class _ProductDrawingThumbnailState extends State<_ProductDrawingThumbnail> {
  String? _cachedUrl;
  bool _loading = true;
  bool _hasError = false;

  final _storageService = AnnotationStorageService();

  @override
  void initState() {
    super.initState();
    _loadDrawingUrl();
  }

  @override
  void didUpdateWidget(covariant _ProductDrawingThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productCode != widget.productCode) {
      _loadDrawingUrl();
    }
  }

  Future<void> _loadDrawingUrl() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    
    try {
      debugPrint('🖼️ Loading drawing for: ${widget.productCode}');
      final url = await _storageService.getDrawingUrl(widget.productCode);
      debugPrint('🖼️ Got URL: $url');
      if (mounted) {
        setState(() {
          _cachedUrl = url;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('🖼️ Error loading drawing: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double size = 60;
    const double radius = 8;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFFE5E5EA),
        highlightColor: const Color(0xFFF2F2F7),
        child: Container(color: Colors.white),
      );
    }

    if (_hasError || _cachedUrl == null) {
      return Container(
        color: const Color(0xFFF2F2F7),
        child: const Center(
          child: Icon(
            CupertinoIcons.doc,
            size: 24,
            color: Color(0xFFC7C7CC),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: _cachedUrl!,
      fit: BoxFit.cover,
      memCacheWidth: 200,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: const Color(0xFFE5E5EA),
        highlightColor: const Color(0xFFF2F2F7),
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFF2F2F7),
        child: const Center(
          child: Icon(
            CupertinoIcons.doc,
            size: 24,
            color: Color(0xFFC7C7CC),
          ),
        ),
      ),
    );
  }
}
