part of '../gantt_screen.dart';

// --- 製品実績入力画面（検査入力画面） ---

enum NextMode {
  nextStepSameProduct,
  nextProductSameStep,
}

enum InspectionStatus { pending, inProgress, done }

String _formatYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

InspectionStatus _statusFromProgress(double progress) {
  if (progress >= 1.0) return InspectionStatus.done;
  if (progress > 0) return InspectionStatus.inProgress;
  return InspectionStatus.pending;
}

String _statusLabel(InspectionStatus status) {
  switch (status) {
    case InspectionStatus.pending:
      return '未';
    case InspectionStatus.inProgress:
      return '作';
    case InspectionStatus.done:
      return '完';
  }
}

class _KoukuFilterBlock extends StatelessWidget {
  const _KoukuFilterBlock({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onClearAll,
    required this.isAllSelected,
    required this.isSelected,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClearAll;
  final bool isAllSelected;
  final bool Function(String) isSelected;

  @override
  Widget build(BuildContext context) {
    if (options.length >= 10) {
      return Padding(
        padding: const EdgeInsets.only(right: 12, bottom: 12),
        child: _KoukuListSelector(
          options: options,
          selected: selected,
          onToggle: onToggle,
          onClearAll: onClearAll,
          isAllSelected: isAllSelected,
          isSelected: isSelected,
        ),
      );
    }
    return _MultiChoiceChips(
      options: options,
      selected: selected,
      onToggle: onToggle,
      onClearAll: onClearAll,
      isAllSelected: isAllSelected,
      isSelected: isSelected,
    );
  }
}

class _KoukuListSelector extends StatelessWidget {
  const _KoukuListSelector({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onClearAll,
    required this.isAllSelected,
    required this.isSelected,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClearAll;
  final bool isAllSelected;
  final bool Function(String) isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = math.min(
      math.max(MediaQuery.sizeOf(context).height * 0.35, 200.0),
      320.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onClearAll,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isAllSelected
                  ? theme.colorScheme.primary.withOpacity(0.08)
                  : null,
              border: Border.all(
                color: isAllSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'すべて',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isAllSelected ? FontWeight.bold : null,
                color:
                    isAllSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        SizedBox(
          height: height,
          child: ListView.builder(
            shrinkWrap: false,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(right: 12, bottom: 12),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final kouku = options[index];
              final selectedItem = isSelected(kouku);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: InkWell(
                  onTap: () => onToggle(kouku),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedItem
                          ? theme.colorScheme.primary.withOpacity(0.08)
                          : null,
                      border: Border.all(
                        color: selectedItem
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      kouku,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: selectedItem ? FontWeight.bold : null,
                        color: selectedItem
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
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

final inspectionDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final inspectionIncompleteOnlyProvider = StateProvider<bool>((ref) => false);

final inspectionSelectedProductIdProvider =
    StateProvider<String?>((ref) => null);

final inspectionSelectedStepIdProvider = StateProvider<String?>((ref) => null);

final _selectedProcessGroupIdProvider = StateProvider<String?>((ref) => null);

final inspectionNextModeProvider =
    StateProvider<NextMode>((ref) => NextMode.nextStepSameProduct);

final inspectionStatusProvider =
    StateProvider<InspectionStatus>((ref) => InspectionStatus.pending);

void _setSelectedProcessStep(WidgetRef ref, String? stepId) {
  ref.read(inspectionSelectedStepIdProvider.notifier).state = stepId;
  ref.read(inspectionFilterProvider.notifier).setProcessStep(stepId);
}

// フィルタ展開領域の最大高さ（iPad 3ペインでの Bottom overflow 再発防止用）
const double kFilterPanelMaxHeight = 360.0;

class ProductResultInputPage extends ConsumerWidget {
  final Project project;

  const ProductResultInputPage({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                const _HeaderBar(),
                Expanded(
                  child: TabBarView(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 280,
                            child: _LeftPane(project: project),
                          ),
                          VerticalDivider(
                            width: 1,
                            thickness: 0.9,
                            color: Theme.of(context).dividerColor,
                          ),
                          Expanded(
                            flex: 3,
                            child: ProductListPane(project: project),
                          ),
                          VerticalDivider(
                            width: 1,
                            thickness: 0.9,
                            color: Theme.of(context).dividerColor,
                          ),
                          SizedBox(
                            width: 380,
                            child: ProcessInputPane(project: project),
                          ),
                        ],
                      ),
                      ProductStatusTabContent(project: project),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            tabs: [
              Tab(text: '検査入力'),
              Tab(text: '製品別ステータス'),
            ],
          ),
          Divider(height: 1),
        ],
      ),
    );
  }
}

class _LeftPane extends StatelessWidget {
  final Project project;

  const _LeftPane({required this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ProcessSelectionCard(),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            children: [
              _CollapsibleFilterPanel(project: project),
              const SizedBox(height: 8),
              Expanded(child: ProcessListPane(project: project)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProcessSelectionCard extends ConsumerWidget {
  const _ProcessSelectionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroupId = ref.watch(_selectedProcessGroupIdProvider);
    final selectedStepId = ref.watch(inspectionSelectedStepIdProvider);
    final groupsAsync = ref.watch(inspectionProcessGroupsProvider);
    final stepsAsync = ref.watch(inspectionProcessStepsProvider);
    final steps = stepsAsync.asData?.value ?? const <ProcessStep>[];
    final groups = groupsAsync.asData?.value ?? const <ProcessGroup>[];

    final theme = Theme.of(context);

    final isLoading = groupsAsync.isLoading || stepsAsync.isLoading;
    final hasError = groupsAsync.hasError || stepsAsync.hasError;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '工程を選択',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed:
                      selectedStepId == null
                          ? null
                          : () {
                              ref.read(_selectedProcessGroupIdProvider.notifier).state =
                                  null;
                              _setSelectedProcessStep(ref, null);
                            },
                  icon: const Icon(Icons.clear),
                  label: const Text('クリア'),
                ),
            ],
          ),
          const SizedBox(height: 8),
            if (hasError)
              Text(
                '工程の読み込みに失敗しました',
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              )
            else if (isLoading && steps.isEmpty)
              const LinearProgressIndicator(minHeight: 3)
            else if (steps.isEmpty)
              Text(
                '工程マスタが取得できませんでした',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error),
              )
            else ...[
              DropdownButtonFormField<String>(
                value: selectedGroupId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '親工程',
                  hintText: '親工程を選択',
                  border: OutlineInputBorder(),
                ),
                items: _sortedProcessGroups(groups)
                    .map(
                      (g) => DropdownMenuItem<String>(
                        value: g.id,
                        child: Text(g.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  ref.read(_selectedProcessGroupIdProvider.notifier).state = value;
                  _setSelectedProcessStep(ref, null);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(selectedStepId == null
                        ? '工程未選択'
                        : '現在: ${_labelForStep(steps, selectedStepId) ?? '工程未選択'}'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: selectedStepId == null
                        ? theme.colorScheme.surfaceVariant
                        : theme.colorScheme.primary.withOpacity(0.12),
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: selectedStepId == null
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _StepChooser(
                selectedGroupId: selectedGroupId,
                selectedStepId: selectedStepId,
                steps: steps,
                onSelect: (stepId) => _setSelectedProcessStep(ref, stepId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String? _labelForStep(List<ProcessStep> steps, String? stepId) {
  if (stepId == null) return null;
  for (final s in steps) {
    if (s.id == stepId) return s.label;
  }
  return null;
}

List<ProcessGroup> _sortedProcessGroups(List<ProcessGroup> groups) {
  return List<ProcessGroup>.from(groups)
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

List<ProcessStep> _sortedProcessSteps(Iterable<ProcessStep> steps) {
  final list = steps.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return list;
}

class _StepChooser extends StatelessWidget {
  final String? selectedGroupId;
  final String? selectedStepId;
  final List<ProcessStep> steps;
  final ValueChanged<String> onSelect;

  const _StepChooser({
    required this.selectedGroupId,
    required this.selectedStepId,
    required this.steps,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedGroupId == null) {
      return const SizedBox.shrink();
    }

    final groupSteps =
        _sortedProcessSteps(steps.where((s) => s.groupId == selectedGroupId));
    if (groupSteps.isEmpty) {
      return Text(
        'この工程グループに工程がありません',
        style:
            theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final step in groupSteps)
              ChoiceChip(
                label: Text(step.label),
                selected: selectedStepId == step.id,
                selectedColor:
                    ProcessColors.fromLabels(stepLabel: step.label, groupLabel: null)
                        .withOpacity(0.15),
                onSelected: (_) => onSelect(step.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _CollapsibleFilterPanel extends ConsumerStatefulWidget {
  final Project project;

  const _CollapsibleFilterPanel({super.key, required this.project});

  @override
  ConsumerState<_CollapsibleFilterPanel> createState() =>
      _CollapsibleFilterPanelState();
}

class _CollapsibleFilterPanelState extends ConsumerState<_CollapsibleFilterPanel> {
  bool _expanded = false;
  late final TextEditingController _sectionController;
  late final TextEditingController _productCodeController;
  late final ProviderSubscription<InspectionFilterState> _filterSub;

  Future<void> _showKoukuSheet(
    BuildContext context,
    List<String> options,
    InspectionFilterNotifier filterNotifier,
    Set<String> initialSelected,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        var selected = Set<String>.from(initialSelected);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('工区を選択', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('すべて'),
                    onTap: () {
                      filterNotifier.clearKouku();
                      selected.clear();
                      setSheetState(() {});
                    },
                    trailing: selected.isEmpty
                        ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                        : null,
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (_, index) {
                        final kouku = options[index];
                        final isSelected = selected.contains(kouku);
                        return ListTile(
                          title: Text(kouku),
                          onTap: () {
                            filterNotifier.toggleKouku(kouku);
                            if (isSelected) {
                              selected.remove(kouku);
                            } else {
                              selected.add(kouku);
                            }
                            setSheetState(() {});
                          },
                          trailing: isSelected
                              ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSetsuSheet(
    BuildContext context,
    List<String> options,
    InspectionFilterNotifier filterNotifier,
    String? initialSelected,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        var current = initialSelected;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('節を選択', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('すべて'),
                onTap: () {
                  filterNotifier.setSetsu(null);
                  Navigator.of(ctx).pop();
                },
                trailing: current == null
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (_, index) {
                    final setsu = options[index];
                    final isSelected = current == setsu;
                    return ListTile(
                      title: Text(setsu),
                      onTap: () {
                        filterNotifier.setSetsu(setsu);
                        current = setsu;
                        Navigator.of(ctx).pop();
                      },
                      trailing: isSelected
                          ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showFloorSheet(
    BuildContext context,
    List<int> options,
    InspectionFilterNotifier filterNotifier,
    int? initialSelected,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        var current = initialSelected;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('階を選択', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('すべて'),
                onTap: () {
                  filterNotifier.setFloor(null);
                  Navigator.of(ctx).pop();
                },
                trailing: current == null
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (_, index) {
                    final floor = options[index];
                    final isSelected = current == floor;
                    return ListTile(
                      title: Text(floor.toString()),
                      onTap: () {
                        filterNotifier.setFloor(floor);
                        current = floor;
                        Navigator.of(ctx).pop();
                      },
                      trailing: isSelected
                          ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSampleCsv(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final content = await rootBundle.loadString('assets/sample/shipping_test_kuku_12.csv');
      await ref
          .read(shippingTableProvider.notifier)
          .loadFromCsvString(content, logPreview: true);
      final shippingState = ref.read(shippingTableProvider);
      final rows = shippingState.rows.length;
      final kukus = shippingState.rows.map((e) => e.kouku.trim()).toSet().length;
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('サンプルCSVを読み込みました rows=$rows kukus=$kukus')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('サンプル読み込みに失敗しました: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _sectionController = TextEditingController();
    _productCodeController = TextEditingController();
    _filterSub =
        ref.listenManual<InspectionFilterState>(inspectionFilterProvider, (prev, next) {
      if (_sectionController.text != next.sectionQuery) {
        _sectionController.text = next.sectionQuery;
      }
      if (_productCodeController.text != next.productCodeQuery) {
        _productCodeController.text = next.productCodeQuery;
      }
    });
  }

  @override
  void dispose() {
    _filterSub.close();
    _sectionController.dispose();
    _productCodeController.dispose();
    super.dispose();
  }

  String _buildFilterSummary(InspectionFilterState filter) {
    final parts = <String>[];
    if (filter.selectedKoukus.isEmpty) {
      parts.add('工区: 未選択');
    } else {
      final koukuList = filter.selectedKoukus.toList()..sort();
      parts.add('工区: ${koukuList.join(', ')}');
    }
    parts.add('種別: ${filter.selectedKind ?? '未選択'}');
    if (filter.selectedKind == '柱') {
      parts.add('節: ${filter.selectedSetsu ?? '未選択'}');
    } else if (filter.selectedKind == '大梁' ||
        filter.selectedKind == '小梁' ||
        filter.selectedKind == '間柱') {
      parts.add('階: ${filter.selectedFloor?.toString() ?? '未選択'}');
    }
    if (filter.sectionQuery.isNotEmpty) {
      parts.add('断面: ${filter.sectionQuery}');
    }
    if (filter.productCodeQuery.isNotEmpty) {
      parts.add('符号: ${filter.productCodeQuery}');
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(inspectionFilterProvider);
    final koukuOptions = ref.watch(koukuCandidatesProvider);
    final kindOptions = ref.watch(kindCandidatesProvider);
    final floorOptions = ref.watch(floorCandidatesProvider);
    final setsuOptions = ref.watch(setsuCandidatesProvider);
    final shippingState = ref.watch(shippingTableProvider);
    final isLoading = shippingState.isLoading;
    final incompleteOnly = ref.watch(inspectionIncompleteOnlyProvider);
    final summary = _buildFilterSummary(filter) + (incompleteOnly ? ' / 未完了のみ' : '');
    final filterNotifier = ref.read(inspectionFilterProvider.notifier);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.bolt),
                        label: const Text('サンプルを読み込む'),
                        onPressed: isLoading ? null : () => _loadSampleCsv(context),
                      ),
                    ],
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                ],
              ),
            ),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            if (_expanded)
              ConstrainedBox(
                constraints: BoxConstraints(
                  // NOTE: Bottom overflow 再発防止のため、フィルタ領域は最大高さを持たせる。
                  // 工区>=10の縦リストが伸びても、この範囲内でスクロールできればOK。
                  maxHeight:
                      math.min(kFilterPanelMaxHeight, MediaQuery.sizeOf(context).height * 0.6),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 12, bottom: 24),
                  physics: const ClampingScrollPhysics(),
                  child: _InspectionFilterPanel(
                    filter: filter,
                    ref: ref,
                    koukuOptions: koukuOptions,
                    kindOptions: kindOptions,
                    floorOptions: floorOptions,
                    setsuOptions: setsuOptions,
                    sectionController: _sectionController,
                    productCodeController: _productCodeController,
                    incompleteOnly: incompleteOnly,
                    onEditKouku: () =>
                        _showKoukuSheet(context, koukuOptions, filterNotifier, filter.selectedKoukus),
                    onEditSetsuOrFloor: () {
                      if (filter.selectedKind == '柱') {
                        _showSetsuSheet(
                            context, setsuOptions, filterNotifier, filter.selectedSetsu);
                      } else {
                        _showFloorSheet(
                            context, floorOptions, filterNotifier, filter.selectedFloor);
                      }
                    },
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _InspectionFilterPanel extends StatelessWidget {
  const _InspectionFilterPanel({
    required this.filter,
    required this.ref,
    required this.koukuOptions,
    required this.kindOptions,
    required this.floorOptions,
    required this.setsuOptions,
    required this.sectionController,
    required this.productCodeController,
    required this.incompleteOnly,
    required this.onEditKouku,
    required this.onEditSetsuOrFloor,
  });

  final InspectionFilterState filter;
  final bool incompleteOnly;
  final List<String> koukuOptions;
  final List<String> kindOptions;
  final List<int> floorOptions;
  final List<String> setsuOptions;
  final TextEditingController sectionController;
  final TextEditingController productCodeController;
  final WidgetRef ref;
  final VoidCallback onEditKouku;
  final VoidCallback onEditSetsuOrFloor;

  @override
  Widget build(BuildContext context) {
    final filterNotifier = ref.read(inspectionFilterProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            label: '工区',
            value: _formatKoukuSummary(filter.selectedKoukus),
            onPressed: onEditKouku,
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '種別',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _KindSelector(
                options: kindOptions,
                selected: filter.selectedKind,
                onSelected: (value) => filterNotifier.setKind(value),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: '節',
            value: filter.selectedKind == '柱'
                ? (filter.selectedSetsu ?? 'すべて')
                : '柱を選択',
            onPressed: filter.selectedKind == '柱' ? onEditSetsuOrFloor : null,
            enabled: filter.selectedKind == '柱',
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: '階',
            value: (filter.selectedKind == '大梁' ||
                    filter.selectedKind == '小梁' ||
                    filter.selectedKind == '間柱')
                ? (filter.selectedFloor?.toString() ?? 'すべて')
                : '梁/間柱を選択',
            onPressed: (filter.selectedKind == '大梁' ||
                    filter.selectedKind == '小梁' ||
                    filter.selectedKind == '間柱')
                ? onEditSetsuOrFloor
                : null,
            enabled: (filter.selectedKind == '大梁' ||
                filter.selectedKind == '小梁' ||
                filter.selectedKind == '間柱'),
          ),
          const SizedBox(height: 6),
          _FilterSection(
            label: '断面寸法',
            child: TextField(
              controller: sectionController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '断面寸法を検索',
                suffixIcon: filter.sectionQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          sectionController.clear();
                          filterNotifier.setSectionQuery('');
                        },
                      ),
              ),
              onChanged: (v) => filterNotifier.setSectionQuery(v.trim()),
            ),
          ),
          const SizedBox(height: 6),
          _FilterSection(
            label: '製品符号',
            child: TextField(
              controller: productCodeController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '製品符号を検索',
                suffixIcon: filter.productCodeQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          productCodeController.clear();
                          filterNotifier.setProductCodeQuery('');
                        },
                      ),
              ),
              onChanged: (v) => filterNotifier.setProductCodeQuery(v.trim()),
            ),
          ),
          const SizedBox(height: 6),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('未完了のみ'),
            value: incompleteOnly,
            onChanged: (v) =>
                ref.read(inspectionIncompleteOnlyProvider.notifier).state = v,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('クリア'),
              onPressed: () {
                filterNotifier.clearAll();
                ref.read(inspectionIncompleteOnlyProvider.notifier).state = false;
                _setSelectedProcessStep(ref, null);
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _formatKoukuSummary(Set<String> koukus) {
  if (koukus.isEmpty) return 'すべて';
  final list = koukus.toList()..sort();
  if (list.length <= 3) return list.join(',');
  final head = list.take(3).join(',');
  return '$head…（${list.length}）';
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final String value;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'すべて' : value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: enabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.outline,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: enabled ? onPressed : null,
            child: const Text('変更'),
          ),
        ],
      ),
    );
  }
}

class _KindSelector extends StatelessWidget {
  const _KindSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        children: [
          for (final option in options)
            ChoiceChip(
              label: Text(option),
              selected: selected == option,
              onSelected: (_) => onSelected(option),
            ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.label,
    required this.child,
    this.helperText,
  });

  final String label;
  final Widget child;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        child,
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ],
    );
  }
}

class _ChoiceChips extends StatelessWidget {
  const _ChoiceChips({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.dense = false,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Text(
        '候補なし',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Wrap(
          spacing: dense ? 6 : 8,
          runSpacing: dense ? 4 : 6,
          children: [
            ChoiceChip(
              label: const Text('すべて'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
            for (final option in options)
              ChoiceChip(
                label: Text(option),
                selected: selected == option,
                onSelected: (_) => onSelected(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _MultiChoiceChips extends StatelessWidget {
  const _MultiChoiceChips({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onClearAll,
    required this.isAllSelected,
    required this.isSelected,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClearAll;
  final bool isAllSelected;
  final bool Function(String) isSelected;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Text(
        '候補なし',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('すべて'),
            selected: isAllSelected,
            onSelected: (_) => onClearAll(),
          ),
          for (final option in options)
            ChoiceChip(
              label: Text(option),
              selected: isSelected(option),
              onSelected: (_) => onToggle(option),
            ),
        ],
      ),
    );
  }
}

class ProductListPane extends ConsumerWidget {
  final Project project;

  const ProductListPane({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProductId = ref.watch(inspectionSelectedProductIdProvider);
    final filteredEntries = ref.watch(inspectionFilteredEntriesProvider(project.id));
    final ganttProductsAsync = ref.watch(ganttProductsProvider(project));
    final hasShipping = ref.watch(shippingRowsProvider).isNotEmpty;
    final selectedStepId = ref.watch(inspectionSelectedStepIdProvider);
    final processStepsAsync = ref.watch(inspectionProcessStepsProvider);
    final selectedStepLabel = processStepsAsync.maybeWhen(
      data: (steps) {
        for (final step in steps) {
          if (step.id == selectedStepId) {
            return step.label;
          }
        }
        return null;
      },
      orElse: () => null,
    );
    final incompleteOnly = ref.watch(inspectionIncompleteOnlyProvider);

    final Set<String>? incompleteIds = ganttProductsAsync.maybeWhen(
      data: (products) =>
          products.where((p) => p.progress < 1).map((p) => p.id).toSet(),
      orElse: () => null,
    );

    final productProgressMap = ganttProductsAsync.maybeWhen(
      data: (products) => {
        for (final p in products) p.id: p,
      },
      orElse: () => <String, GanttProduct>{},
    );

    final displayEntries = filteredEntries
        .where((entry) {
          if (!incompleteOnly) return true;
          final id = entry.product?.id;
          if (id == null) return false;
          return incompleteIds?.contains(id) == true;
        })
        .toList();

    if (selectedProductId == null && displayEntries.isNotEmpty) {
      InspectionProductEntry? firstSelectable;
      for (final entry in displayEntries) {
        if (entry.product != null) {
          firstSelectable = entry;
          break;
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(inspectionSelectedProductIdProvider) == null &&
            firstSelectable?.product != null) {
          ref.read(inspectionSelectedProductIdProvider.notifier).state =
              firstSelectable!.product!.id;
        }
      });
    }

    return _ProductListView(
      entries: displayEntries,
      selectedProductId: selectedProductId,
      productProgressMap: productProgressMap,
      hasShipping: hasShipping,
      selectedStepLabel: selectedStepLabel,
      onSelectProduct: (product) {
        ref.read(inspectionSelectedProductIdProvider.notifier).state = product.id;
      },
    );
  }
}

class _ProductListView extends StatelessWidget {
  const _ProductListView({
    required this.entries,
    required this.selectedProductId,
    required this.productProgressMap,
    required this.hasShipping,
    required this.selectedStepLabel,
    required this.onSelectProduct,
  });

  final List<InspectionProductEntry> entries;
  final String? selectedProductId;
  final Map<String, GanttProduct> productProgressMap;
  final bool hasShipping;
  final String? selectedStepLabel;
  final ValueChanged<Product> onSelectProduct;

  @override
  Widget build(BuildContext context) {
    if (!hasShipping) {
      return Center(
        child: Text(
          'CSV未読込（出荷表を読み込んでください）',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (entries.isEmpty) {
      return const Center(child: Text('該当する製品がありません'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(
                '製品（フィルタ結果）',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(selectedStepLabel != null ? '工程: $selectedStepLabel' : '工程未選択'),
                visualDensity: VisualDensity.compact,
                backgroundColor: selectedStepLabel != null
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                    : Theme.of(context).colorScheme.surfaceVariant,
                labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selectedStepLabel != null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final product = entry.product;
              final shippingRow = entry.shippingRow;
              final isSelected = product != null && selectedProductId == product.id;
              final gantt = product != null ? productProgressMap[product.id] : null;
              final remainingCount =
                  gantt?.tasks.where((t) => t.progress < 1).length;
              // TODO: 今はPDFビューア動作確認のために先頭1件だけテストURLを使用している。
              //       本番では Product.drawingPdfUrl を正式に持たせて差し替えること。
              String? drawingUrl;
              if (product != null) {
                try {
                  final dynamicUrl = (product as dynamic).drawingPdfUrl;
                  if (dynamicUrl is String && dynamicUrl.isNotEmpty) {
                    drawingUrl = dynamicUrl;
                  }
                } catch (_) {
                  drawingUrl = null;
                }
              }
              if (product != null) {
                drawingUrl ??= index == 0 ? kTestDrawingPdfUrl : null;
              }
              final hasDrawing = drawingUrl != null && drawingUrl.isNotEmpty;
              final isPriority = product != null &&
                  product.overallEndDate != null &&
                  product.overallStatus != 'completed' &&
                  product.overallEndDate!.isBefore(DateTime.now());
              final badge = isPriority
                  ? Chip(
                      label: const Text('優先'),
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withOpacity(0.9),
                    )
                  : null;

              return Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
                      : null,
                  border: isSelected
                      ? Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                        )
                      : null,
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  title: Text(
                    shippingRow.productCode.isNotEmpty
                        ? shippingRow.productCode
                        : (product?.productCode.isNotEmpty == true
                            ? product!.productCode
                            : (product?.name ?? '-')),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) {
                          final sectionLabel = () {
                            if (shippingRow.sectionSize.isNotEmpty) {
                              return shippingRow.sectionSize;
                            }
                            if (product != null && product.section.isNotEmpty) {
                              return product.section;
                            }
                            return '-';
                          }();
                          final lengthMm = shippingRow.lengthMm;
                          final lengthLabel =
                              lengthMm > 0 ? '長さ: $lengthMm mm' : '長さ: -';
                          final remainingLabel = remainingCount != null
                              ? '残: $remainingCount'
                              : '残: ?';
                          final locationParts = <String>[];
                          final kouku = shippingRow.kouku.isNotEmpty
                              ? shippingRow.kouku
                              : (product?.storyOrSet ?? '');
                          if (kouku.isNotEmpty) {
                            locationParts.add('工区: $kouku');
                          }
                          final floor = shippingRow.floor;
                          if (floor != null) {
                            locationParts.add('階: $floor');
                          }
                          final setsuValue = shippingRow.setsu ??
                              (product?.grid.isNotEmpty == true
                                  ? product!.grid
                                  : (product?.storyOrSet.isNotEmpty == true
                                      ? product!.storyOrSet
                                      : null));
                          if (setsuValue != null && setsuValue.isNotEmpty) {
                            locationParts.add('節: $setsuValue');
                          }
                          final locationLabel = locationParts.join(' / ');
                          final kindLabel = shippingRow.kind.trim();
                          final line = [
                            if (kindLabel.isNotEmpty) '種別: $kindLabel',
                            '断面: $sectionLabel',
                            lengthLabel,
                            remainingLabel,
                            if (locationLabel.isNotEmpty) locationLabel,
                          ].join('   ');
                          return Text(
                            line,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf),
                        tooltip: hasDrawing
                            ? '図面を開く（Safari／マークアップ可）'
                            : '図面未登録',
                        onPressed:
                            !hasDrawing ? null : () => _openDrawingPdf(context, drawingUrl!),
                      ),
                      if (badge != null) badge,
                    ],
                  ),
                  selected: isSelected,
                  selectedTileColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  onTap: product == null ? null : () => onSelectProduct(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ProcessListPane extends ConsumerStatefulWidget {
  final Project project;

  const ProcessListPane({super.key, required this.project});

  @override
  ConsumerState<ProcessListPane> createState() => _ProcessListPaneState();
}

class _ProcessListPaneState extends ConsumerState<ProcessListPane> {
  final Set<String> _expandedGroupIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final selectedProductId = ref.watch(inspectionSelectedProductIdProvider);
    final selectedStepId = ref.watch(inspectionSelectedStepIdProvider);
    final productsAsync = ref.watch(productsByProjectProvider(widget.project.id));
    final filteredProducts = ref.watch(filteredProductsProvider(widget.project.id));
    final ganttProductsAsync = ref.watch(ganttProductsProvider(widget.project));

    Product? _findSelected(List<Product> products) {
      if (selectedProductId == null) return null;
      for (final p in products) {
        if (p.id == selectedProductId) return p;
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: const SizedBox.shrink(),
        ),
        const Divider(height: 1),
        Expanded(
          child: ganttProductsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('工程の読み込みに失敗しました: $e')),
            data: (products) {
              if (selectedProductId == null) {
                return const SizedBox.shrink();
              }
              final product = products
                  .where((p) => p.id == selectedProductId)
                  .cast<GanttProduct?>()
                  .firstWhere((p) => p != null, orElse: () => null);
              if (product == null) {
                return const Center(child: Text('対象製品の工程が見つかりません'));
              }

              final grouped = <String, List<GanttTask>>{};
              for (final task in product.tasks) {
                final key = task.processGroupId ?? 'unknown';
                grouped.putIfAbsent(key, () => <GanttTask>[]).add(task);
              }

              final groups = grouped.entries.toList()
                ..sort((a, b) {
                  final aSort = a.value.first.processGroupSort ?? 9999;
                  final bSort = b.value.first.processGroupSort ?? 9999;
                  return aSort.compareTo(bSort);
                });

              return ListView(
                children: [
                  for (final entry in groups) ...[
                    _ProcessGroupSection(
                      groupId: entry.key,
                      title: entry.value.first.processGroupLabel ?? '未分類',
                      steps: entry.value,
                      isExpanded: _expandedGroupIds.contains(entry.key),
                      onToggleExpanded: () {
                        setState(() {
                          if (_expandedGroupIds.contains(entry.key)) {
                            _expandedGroupIds.remove(entry.key);
                          } else {
                            _expandedGroupIds.add(entry.key);
                          }
                        });
                      },
                      selectedStepId: selectedStepId,
                      onSelectStep: (task) {
                        _setSelectedProcessStep(ref, task.stepId);
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<void> _openDrawingPdf(BuildContext context, String urlString) async {
  final uri = Uri.tryParse(urlString);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('図面のURLが不正です')),
    );
    return;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('図面は Safari で開きます。右上の共有→「マークアップ」でPencilチェックできます。'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  if (!await canLaunchUrl(uri)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('図面を開けませんでした')),
    );
    return;
  }

  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('図面を開けませんでした')),
    );
  }
}

class _ProcessGroupSection extends StatelessWidget {
  final String groupId;
  final String title;
  final List<GanttTask> steps;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final String? selectedStepId;
  final ValueChanged<GanttTask> onSelectStep;

  const _ProcessGroupSection({
    required this.groupId,
    required this.title,
    required this.steps,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.selectedStepId,
    required this.onSelectStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggleExpanded,
          child: Container(
            width: double.infinity,
            color: theme.colorScheme.surfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...steps.map(
            (task) => _ProcessStepRow(
              task: task,
              isSelected: selectedStepId == task.stepId,
              onTap: () => onSelectStep(task),
            ),
          ),
      ],
    );
  }
}

class _ProcessStepRow extends StatelessWidget {
  final GanttTask task;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProcessStepRow({
    required this.task,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
        : Colors.transparent;
    final status = _statusFromProgress(task.progress);
    final statusColor = switch (status) {
      InspectionStatus.pending => Theme.of(context).colorScheme.outline,
      InspectionStatus.inProgress => Theme.of(context).colorScheme.secondary,
      InspectionStatus.done => Theme.of(context).colorScheme.tertiary,
    };
    return InkWell(
      onTap: onTap,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: statusColor.withOpacity(0.15),
              child: Text(
                _statusLabel(status),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.stepLabel ?? task.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '最終: ${_formatYmd(task.end)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ProcessGuardMessage extends StatelessWidget {
  final String message;

  const _ProcessGuardMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 28),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '左ペインの工程チップを選択すると入力できます。',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProcessInputPane extends ConsumerStatefulWidget {
  final Project project;

  const ProcessInputPane({super.key, required this.project});

  @override
  ConsumerState<ProcessInputPane> createState() => _ProcessInputPaneState();
}

class _ProcessInputPaneState extends ConsumerState<ProcessInputPane> {
  final _formKey = GlobalKey<FormState>();
  final _l1Ctrl = TextEditingController();
  final _l2Ctrl = TextEditingController();
  final _h1Ctrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _saveService = ProcessProgressSaveService();
  final _progressRepo = ProcessProgressDailyRepository();
  bool _isSaving = false;
  String _inspectorName = '-'; // TODO: 認証済みユーザー名が取れるようになったら差し替える

  Future<void> _moveToNextStepSameProduct() async {
    final productId = ref.read(inspectionSelectedProductIdProvider);
    final currentStepId = ref.read(inspectionSelectedStepIdProvider);
    final ganttProducts = ref.read(ganttProductsProvider(widget.project)).asData?.value;
    final messenger = ScaffoldMessenger.of(context);
    if (productId == null || currentStepId == null || ganttProducts == null) {
      messenger.showSnackBar(const SnackBar(content: Text('製品または工程が選択されていません')));
      return;
    }
    GanttProduct? product;
    for (final p in ganttProducts) {
      if (p.id == productId) {
        product = p;
        break;
      }
    }
    if (product == null) {
      messenger.showSnackBar(const SnackBar(content: Text('工程リストが取得できませんでした')));
      return;
    }
    final steps = product.tasks;
    final index = steps.indexWhere((t) => t.stepId == currentStepId);
    if (index == -1 || index + 1 >= steps.length) {
      messenger.showSnackBar(const SnackBar(content: Text('この製品の工程はすべて処理済みです')));
      return;
    }
    final next = steps[index + 1];
    _setSelectedProcessStep(ref, next.stepId);
  }

  Future<void> _moveToNextProductSameStep() async {
    final currentStepId = ref.read(inspectionSelectedStepIdProvider);
    final currentProductId = ref.read(inspectionSelectedProductIdProvider);
    final products = ref.read(filteredProductsProvider(widget.project.id));
    final ganttProducts = ref.read(ganttProductsProvider(widget.project)).asData?.value;
    final messenger = ScaffoldMessenger.of(context);

    if (currentStepId == null || currentProductId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('製品または工程が選択されていません')));
      return;
    }
    if (products.isEmpty || ganttProducts == null) {
      messenger.showSnackBar(const SnackBar(content: Text('対象製品のリストが取得できませんでした')));
      return;
    }
    final index = products.indexWhere((p) => p.id == currentProductId);
    if (index == -1 || index + 1 >= products.length) {
      messenger.showSnackBar(const SnackBar(content: Text('次の製品はありません')));
      return;
    }
    final nextProduct = products[index + 1];
    ref.read(inspectionSelectedProductIdProvider.notifier).state = nextProduct.id;

    GanttProduct? nextGanttProduct;
    for (final p in ganttProducts) {
      if (p.id == nextProduct.id) {
        nextGanttProduct = p;
        break;
      }
    }
    if (nextGanttProduct == null) {
      messenger.showSnackBar(const SnackBar(content: Text('この製品の工程が取得できませんでした')));
      return;
    }
    GanttTask? sameStep;
    for (final t in nextGanttProduct.tasks) {
      if (t.stepId == currentStepId) {
        sameStep = t;
        break;
      }
    }
    if (sameStep != null) {
      _setSelectedProcessStep(ref, sameStep.stepId);
    } else if (nextGanttProduct.tasks.isNotEmpty) {
      _setSelectedProcessStep(ref, nextGanttProduct.tasks.first.stepId);
      messenger.showSnackBar(const SnackBar(content: Text('同じ工程がないため最初の工程を選択しました')));
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('この製品には工程がありません')));
    }
  }

  Future<void> _onSaveAndMoveNext() async {
    final ok = await _saveCurrentInspection(context);
    if (!ok) return;
    final mode = ref.read(inspectionNextModeProvider);
    switch (mode) {
      case NextMode.nextStepSameProduct:
        await _moveToNextStepSameProduct();
        break;
      case NextMode.nextProductSameStep:
        await _moveToNextProductSameStep();
        break;
    }
  }

  InspectionStatus _statusFromQty(int doneQty, int quantity) {
    if (doneQty <= 0) return InspectionStatus.pending;
    if (quantity > 0 && doneQty >= quantity) return InspectionStatus.done;
    return InspectionStatus.inProgress;
  }

  Future<void> _loadExistingProgress() async {
    final productId = ref.read(inspectionSelectedProductIdProvider);
    final stepId = ref.read(inspectionSelectedStepIdProvider);
    final date = ref.read(inspectionDateProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (productId == null || stepId == null) {
      ref.read(inspectionStatusProvider.notifier).state =
          InspectionStatus.pending;
      _l1Ctrl.clear();
      _l2Ctrl.clear();
      _h1Ctrl.clear();
      _noteCtrl.clear();
      return;
    }

    try {
      final rows = await _progressRepo.fetchDaily(
        widget.project.id,
        productId,
        filterStepId: stepId,
      );
      ProcessProgressDaily? matched;
      for (final r in rows) {
        final only = DateTime(r.date.year, r.date.month, r.date.day);
        if (only.year == date.year &&
            only.month == date.month &&
            only.day == date.day) {
          matched = r;
          break;
        }
      }

      final product = _selectedProductFrom(ref, productId);
      final qty = product?.quantity ?? 0;
      ref.read(inspectionStatusProvider.notifier).state =
          _statusFromQty(matched?.doneQty ?? 0, qty);
      _noteCtrl.text = matched?.note ?? '';
      // TODO: 備考から実測値をパースする仕様が固まったら復元する
      _l1Ctrl.clear();
      _l2Ctrl.clear();
      _h1Ctrl.clear();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('既存実績の読み込みに失敗しました: $e')),
      );
      ref.read(inspectionStatusProvider.notifier).state =
          InspectionStatus.pending;
      _l1Ctrl.clear();
      _l2Ctrl.clear();
      _h1Ctrl.clear();
      _noteCtrl.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    // TODO: 認証ユーザーの取得方法を決めたらここで代入する
    _inspectorName = _inspectorName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingProgress();
    });
  }

  @override
  void dispose() {
    _l1Ctrl.dispose();
    _l2Ctrl.dispose();
    _h1Ctrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Product? _selectedProductFrom(WidgetRef ref, String? productId) {
    if (productId == null) return null;
    final filtered = ref.read(filteredProductsProvider(widget.project.id));
    for (final p in filtered) {
      if (p.id == productId) return p;
    }
    final productsAsync = ref.read(productsByProjectProvider(widget.project.id));
    final products = productsAsync.asData?.value ?? const <Product>[];
    for (final p in products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  GanttTask? _selectedTaskFrom(
    List<GanttProduct> products,
    String? productId,
    String? stepId,
  ) {
    if (productId == null || stepId == null) return null;
    for (final product in products) {
      if (product.id == productId) {
        for (final task in product.tasks) {
          if (task.stepId == stepId) return task;
        }
      }
    }
    return null;
  }

  Future<bool> _saveCurrentInspection(BuildContext context) async {
    if (_isSaving) return false;
    final messenger = ScaffoldMessenger.of(context);
    final productId = ref.read(inspectionSelectedProductIdProvider);
    final stepId = ref.read(inspectionSelectedStepIdProvider);
    final inspectionDate = ref.read(inspectionDateProvider);
    final status = ref.read(inspectionStatusProvider);

    if (productId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('製品を選択してください')));
      return false;
    }
    if (stepId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('工程を選択してください')));
      return false;
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (inspectionDate.isAfter(todayOnly)) {
      messenger.showSnackBar(const SnackBar(content: Text('未来日の検査は登録できません')));
      return false;
    }

    final formState = _formKey.currentState;
    if (formState == null) {
      messenger.showSnackBar(const SnackBar(content: Text('フォームの初期化に失敗しました')));
      return false;
    }
    if (!formState.validate()) {
      return false;
    }

    final product = _selectedProductFrom(ref, productId);

    final doneQty = status == InspectionStatus.done
        ? (product?.quantity != null && product!.quantity > 0 ? product.quantity : 1)
        : 0;

    final note = _noteCtrl.text.trim();
    final measurementNote = [
      if (_l1Ctrl.text.trim().isNotEmpty) 'L1: ${_l1Ctrl.text.trim()}',
      if (_l2Ctrl.text.trim().isNotEmpty) 'L2: ${_l2Ctrl.text.trim()}',
      if (_h1Ctrl.text.trim().isNotEmpty) 'H1: ${_h1Ctrl.text.trim()}',
    ].join(' / ');
    final mergedNote = [
      note,
      if (measurementNote.isNotEmpty)
        '測定値: $measurementNote', // TODO: 専用フィールドが用意されたら移行する
    ].where((e) => e.isNotEmpty).join('\n');

    setState(() {
      _isSaving = true;
    });

    try {
      await _saveService.upsertDaily(
        projectId: widget.project.id,
        productId: productId,
        stepId: stepId,
        date: inspectionDate,
        doneQty: doneQty,
        note: mergedNote,
      );
      messenger.showSnackBar(const SnackBar(content: Text('検査実績を保存しました')));
      return true;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('保存に失敗しました。通信状態を確認してください: $e')),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedProductId = ref.watch(inspectionSelectedProductIdProvider);
    final selectedStepId = ref.watch(inspectionSelectedStepIdProvider);
    final status = ref.watch(inspectionStatusProvider);
    final nextMode = ref.watch(inspectionNextModeProvider);
    final inspectionDate = ref.watch(inspectionDateProvider);
    final productsAsync = ref.watch(productsByProjectProvider(widget.project.id));
    final ganttProductsAsync = ref.watch(ganttProductsProvider(widget.project));
    final processStepsAsync = ref.watch(inspectionProcessStepsProvider);
    final selectedStepLabel = processStepsAsync.maybeWhen(
      data: (steps) {
        for (final step in steps) {
          if (step.id == selectedStepId) {
            return step.label;
          }
        }
        return null;
      },
      orElse: () => null,
    );

    ref.listen<String?>(
      inspectionSelectedProductIdProvider,
      (_, __) => _loadExistingProgress(),
    );
    ref.listen<String?>(
      inspectionSelectedStepIdProvider,
      (_, __) => _loadExistingProgress(),
    );
    ref.listen<DateTime>(
      inspectionDateProvider,
      (_, __) => _loadExistingProgress(),
    );

    final statusSelection = [
      status == InspectionStatus.pending,
      status == InspectionStatus.inProgress,
      status == InspectionStatus.done,
    ];

    GanttTask? _selectedTaskFor(List<GanttProduct> products) =>
        _selectedTaskFrom(products, selectedProductId, selectedStepId);

    final guardMessage = () {
      if (selectedProductId == null && selectedStepId == null) {
        return '左の製品と工程を選択してください';
      }
      if (selectedProductId == null) return '左の製品を選択してください';
      if (selectedStepId == null) return '左の工程を選択してください';
      return '';
    }();
    final shouldGuard = guardMessage.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: productsAsync.when(
                loading: () => Text(
                  '製品: 読み込み中',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                error: (e, _) => Text(
                  '製品読込エラー: $e',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                data: (products) {
                  Product? selectedProduct =
                      _selectedProductFrom(ref, selectedProductId);
                  if (selectedProduct == null && selectedProductId != null) {
                    for (final p in products) {
                      if (p.id == selectedProductId) {
                        selectedProduct = p;
                        break;
                      }
                    }
                  }
                  final currentTask = ganttProductsAsync.maybeWhen(
                    data: (list) => _selectedTaskFor(list),
                    orElse: () => null,
                  );
                  final stepLabel =
                      selectedStepLabel ?? currentTask?.stepLabel ?? currentTask?.name ?? '工程未選択';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '製品: ${selectedProduct?.productCode.isNotEmpty == true ? selectedProduct!.productCode : selectedProduct?.name ?? '製品未選択'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '工程: $stepLabel',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '検査日: ${_formatYmd(inspectionDate)}   検査者: $_inspectorName',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: shouldGuard
              ? _ProcessGuardMessage(message: guardMessage)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final requireNumbers = status == InspectionStatus.done;
                    String? numberValidator(String? value) {
                      if (!requireNumbers) return null;
                      if (value == null || value.trim().isEmpty) {
                        return '必須です';
                      }
                      return double.tryParse(value.trim()) != null
                          ? null
                          : '数値を入力してください';
                    }

                    return SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '状態',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                ToggleButtons(
                                  isSelected: statusSelection,
                                  borderRadius: BorderRadius.circular(8),
                                  constraints: const BoxConstraints(
                                    minHeight: 40,
                                    minWidth: 72,
                                  ),
                                  onPressed: (index) {
                                    final notifier =
                                        ref.read(inspectionStatusProvider.notifier);
                                    switch (index) {
                                      case 0:
                                        notifier.state = InspectionStatus.pending;
                                        break;
                                      case 1:
                                        notifier.state = InspectionStatus.inProgress;
                                        break;
                                      case 2:
                                        notifier.state = InspectionStatus.done;
                                        break;
                                    }
                                  },
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('未'),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('作業中'),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('完'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '実測値',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                _NumericField(
                                  label: '長さ L1 (mm)',
                                  controller: _l1Ctrl,
                                  validator: numberValidator,
                                ),
                                const SizedBox(height: 12),
                                _NumericField(
                                  label: '長さ L2 (mm)',
                                  controller: _l2Ctrl,
                                  validator: numberValidator,
                                ),
                                const SizedBox(height: 12),
                                _NumericField(
                                  label: '高さ H1 (mm)',
                                  controller: _h1Ctrl,
                                  validator: numberValidator,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '備考',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _noteCtrl,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: '検査時の気付きを入力',
                                    helperText: '例）UT結果や特記事項を記載',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Text(
                                      '保存後の移動',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(width: 12),
                                    DropdownButton<NextMode>(
                                      value: nextMode,
                                      items: NextMode.values
                                          .map(
                                            (mode) => DropdownMenuItem<NextMode>(
                                              value: mode,
                                              child: Text(
                                                mode == NextMode.nextStepSameProduct
                                                    ? '同一製品の次工程'
                                                    : '同一工程の次製品',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (mode) {
                                        if (mode != null) {
                                          ref
                                              .read(inspectionNextModeProvider.notifier)
                                              .state = mode;
                                          // TODO: NextMode を保存する
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          // TODO: 入力を破棄して一覧に戻す
                        },
                  child: const Text('キャンセル'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isSaving || shouldGuard
                      ? null
                      : () async {
                          await _saveCurrentInspection(context);
                        },
                  child: const Text('保存'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('保存して次の工程へ'),
                  onPressed: _isSaving || shouldGuard
                      ? null
                      : () async {
                          await _onSaveAndMoveNext();
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NumericField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const _NumericField({
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

