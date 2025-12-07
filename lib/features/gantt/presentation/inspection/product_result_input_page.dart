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

Color _statusColor(BuildContext context, InspectionStatus status) {
  final scheme = Theme.of(context).colorScheme;
  switch (status) {
    case InspectionStatus.pending:
      return scheme.outlineVariant;
    case InspectionStatus.inProgress:
      return scheme.secondary;
    case InspectionStatus.done:
      return scheme.primary;
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

final inspectionNextModeProvider =
    StateProvider<NextMode>((ref) => NextMode.nextStepSameProduct);

final inspectionStatusProvider =
    StateProvider<InspectionStatus>((ref) => InspectionStatus.pending);

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

bool _isColumnType(String memberType) {
  // TODO: COLUMN_XX などの派生コードが増えたらここに追加する
  return memberType == 'COLUMN';
}

class _LeftPane extends StatelessWidget {
  final Project project;

  const _LeftPane({required this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CollapsibleFilterPanel(project: project),
        const SizedBox(height: 8),
        Expanded(child: ProcessListPane(project: project)),
      ],
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

  List<String> _options(Iterable<String> values) {
    final set = values.where((v) => v.isNotEmpty).toSet().toList()..sort();
    return set;
  }

  List<String> _memberTypeOptions(Iterable<String> values) {
    final list = values.where((v) => v.isNotEmpty).toSet().toList();
    int order(String v) {
      switch (v) {
        case 'COLUMN':
          return 0;
        case 'GIRDER':
          return 1;
        default:
          return 2;
      }
    }

    list.sort((a, b) {
      final oa = order(a);
      final ob = order(b);
      if (oa != ob) return oa.compareTo(ob);
      return a.compareTo(b);
    });
    return list;
  }

  String _memberTypeLabel(String code) {
    switch (code) {
      case 'COLUMN':
        return '柱';
      case 'GIRDER':
        return '大梁・小梁・間柱・他';
      default:
        return code;
    }
  }

  String _buildSummaryLabel({
    required String prefix,
    required List<String> allOptions,
    required Set<String> selected,
    int limit = 3,
  }) {
    if (allOptions.isEmpty) {
      return '$prefix: なし';
    }
    if (selected.isEmpty) {
      return '$prefix: すべて';
    }
    final ordered = allOptions.where((o) => selected.contains(o)).toList();
    if (ordered.length <= limit) {
      final joined = ordered.join(', ');
      return '$prefix: $joined';
    }
    final head = ordered.take(limit).join(', ');
    final rest = ordered.length - limit;
    return '$prefix: $head 他${rest}件';
  }

  String _summaryPart(
    String label,
    Set<String> values, {
    int limit = 3,
    String Function(String value)? labelBuilder,
  }) {
    if (values.isEmpty) return '$label: すべて';
    final mapped = values.map(labelBuilder ?? (v) => v).toList();
    if (mapped.length <= limit) return '$label: ${mapped.join(', ')}';
    final head = mapped.take(limit).join(', ');
    final rest = mapped.length - limit;
    return '$label: $head 他${rest}件';
  }

  String _buildFilterSummary(ProductFilterState filter) {
    final parts = <String>[];
    parts.add(_summaryPart('工区', filter.selectedBlocks, limit: 3));
    parts.add(
      _summaryPart(
        '部材',
        filter.selectedMemberTypes,
        labelBuilder: _memberTypeLabel,
        limit: 2,
      ),
    );
    parts.add(_summaryPart('節', filter.selectedSegments, limit: 3));
    parts.add(_summaryPart('階', filter.selectedFloors, limit: 3));
    parts.add(_summaryPart('断面', filter.selectedSections, limit: 1));
    parts.add('未完了:${filter.incompleteOnly ? 'ON' : 'OFF'}');
    return parts.join('   ');
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(productFilterProvider);
    final filterNotifier = ref.read(productFilterProvider.notifier);
    final inspectionDate = ref.watch(inspectionDateProvider);
    final productsAsync = ref.watch(productsByProjectProvider(widget.project.id));
    final allProducts = productsAsync.asData?.value ?? const <Product>[];

    final columnProducts =
        allProducts.where((p) => _isColumnType(p.memberType)).toList();
    final nonColumnProducts =
        allProducts.where((p) => !_isColumnType(p.memberType)).toList();

    final blockFilters =
        _options(allProducts.map((p) => p.area.isNotEmpty ? p.area : p.storyOrSet));
    final segmentOptions = _options(columnProducts.map((p) => p.storyOrSet));
    final floorOptions = _options(
      nonColumnProducts.map((p) => p.storyOrSet),
    ); // TODO: floor フィールドを導入したら storyOrSet の代わりに floor を使う
    final memberTypeFilters = _memberTypeOptions(allProducts.map((p) => p.memberType));
    final sectionFilters = _options(allProducts.map((p) => p.section));

    final summary = _buildFilterSummary(filter);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
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
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _ProductFilterPanel(
                inspectionDate: inspectionDate,
                ref: ref,
                segments: segmentOptions,
                floors: floorOptions,
                memberTypes: memberTypeFilters,
                sections: sectionFilters,
                allBlocks: blockFilters,
                filter: filter,
                onToggleBlock: filterNotifier.toggleBlock,
                onToggleSegment: filterNotifier.toggleSegment,
                onToggleFloor: filterNotifier.toggleFloor,
                onToggleMemberType: filterNotifier.toggleMemberType,
                onToggleSection: filterNotifier.toggleSection,
                onClearFilters: filterNotifier.clearAll,
                onToggleIncompleteOnly: filterNotifier.setIncompleteOnly,
                onPickDate: (picked) =>
                    ref.read(inspectionDateProvider.notifier).state = picked,
              ),
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class ProductListPane extends ConsumerWidget {
  final Project project;

  const ProductListPane({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productFilterProvider);
    final selectedProductId = ref.watch(inspectionSelectedProductIdProvider);
    final filteredProducts = ref.watch(filteredProductsProvider(project.id));
    final ganttProductsAsync = ref.watch(ganttProductsProvider(project));

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

    final displayProducts = filteredProducts
        .where(
          (p) => !filter.incompleteOnly || incompleteIds?.contains(p.id) == true,
        )
        .toList();

    if (selectedProductId == null && displayProducts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(inspectionSelectedProductIdProvider) == null) {
          ref.read(inspectionSelectedProductIdProvider.notifier).state =
              displayProducts.first.id;
          ref.read(inspectionSelectedStepIdProvider.notifier).state = null;
        }
      });
    }

    return _ProductListView(
      displayProducts: displayProducts,
      selectedProductId: selectedProductId,
      productProgressMap: productProgressMap,
      onSelectProduct: (product) {
        ref.read(inspectionSelectedProductIdProvider.notifier).state = product.id;
        ref.read(inspectionSelectedStepIdProvider.notifier).state = null;
      },
    );
  }
}

class _ProductFilterPanel extends StatelessWidget {
  const _ProductFilterPanel({
    required this.inspectionDate,
    required this.ref,
    required this.segments,
    required this.floors,
    required this.memberTypes,
    required this.sections,
    required this.allBlocks,
    required this.filter,
    required this.onToggleBlock,
    required this.onToggleSegment,
    required this.onToggleFloor,
    required this.onToggleMemberType,
    required this.onToggleSection,
    required this.onClearFilters,
    required this.onToggleIncompleteOnly,
    required this.onPickDate,
  });

  final DateTime inspectionDate;
  final WidgetRef ref;
  final List<String> segments;
  final List<String> floors;
  final List<String> memberTypes;
  final List<String> sections;
  final List<String> allBlocks;
  final ProductFilterState filter;
  final ValueChanged<String> onToggleBlock;
  final ValueChanged<String> onToggleSegment;
  final ValueChanged<String> onToggleFloor;
  final ValueChanged<String> onToggleMemberType;
  final ValueChanged<String> onToggleSection;
  final VoidCallback onClearFilters;
  final ValueChanged<bool> onToggleIncompleteOnly;
  final ValueChanged<DateTime> onPickDate;

  String _memberTypeLabel(String code) {
    switch (code) {
      case 'COLUMN':
        return '柱';
      case 'GIRDER':
        return '大梁・小梁・間柱・他';
      default:
        return code;
    }
  }

  String _buildSummaryLabel({
    required String prefix,
    required List<String> allOptions,
    required Set<String> selected,
    int limit = 3,
  }) {
    if (allOptions.isEmpty) {
      return '$prefix: なし';
    }
    if (selected.isEmpty) {
      return '$prefix: すべて';
    }
    final ordered = allOptions.where((o) => selected.contains(o)).toList();
    if (ordered.length <= limit) {
      final joined = ordered.join(', ');
      return '$prefix: $joined';
    }
    final head = ordered.take(limit).join(', ');
    final rest = ordered.length - limit;
    return '$prefix: $head 他${rest}件';
  }

  @override
  Widget build(BuildContext context) {
    final selectedMemberTypes = filter.selectedMemberTypes;
    final includeColumns =
        selectedMemberTypes.isEmpty || selectedMemberTypes.contains('COLUMN');
    final includeNonColumns =
        selectedMemberTypes.isEmpty ||
        selectedMemberTypes.any((t) => !_isColumnType(t));

    final showSegmentFilter = includeColumns && segments.isNotEmpty;
    final showFloorFilter = includeNonColumns && floors.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () => _showBlockMultiSelectSheet(context, ref, allBlocks),
            child: const Text('工区を選択'),
          ),
          const SizedBox(height: 8),
          if (showSegmentFilter)
            if (segments.length <= 10)
              _MultiSelectChips(
                label: '節',
                options: segments,
                selected: filter.selectedSegments,
                onToggled: onToggleSegment,
              )
            else
              _SegmentFilterButton(
                segments: segments,
                selected: filter.selectedSegments,
                labelBuilder: (selected) => _buildSummaryLabel(
                  prefix: '節',
                  allOptions: segments,
                  selected: selected,
                ),
              ),
          if (showFloorFilter)
            if (floors.length <= 10)
              _MultiSelectChips(
                label: '階',
                options: floors,
                selected: filter.selectedFloors,
                onToggled: onToggleFloor,
              )
            else
              _FloorFilterButton(
                floors: floors,
                selected: filter.selectedFloors,
                labelBuilder: (selected) => _buildSummaryLabel(
                  prefix: '階',
                  allOptions: floors,
                  selected: selected,
                ),
              ),
          const SizedBox(height: 8),
          _HorizontalChipSelector(
            label: '部材',
            options: memberTypes,
            selected: filter.selectedMemberTypes,
            onToggled: onToggleMemberType,
            labelBuilder: _memberTypeLabel,
          ),
          const SizedBox(height: 8),
          _SectionFilterButton(
            sections: sections,
            selected: filter.selectedSections,
            labelBuilder: (selected) => _buildSummaryLabel(
              prefix: '断面',
              allOptions: sections,
              selected: selected,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('未完了のみ'),
            value: filter.incompleteOnly,
            onChanged: onToggleIncompleteOnly,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: const Text('クリア'),
              selected: false,
              onSelected: (_) => onClearFilters(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalChipSelector extends StatelessWidget {
  const _HorizontalChipSelector({
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggled,
    this.labelBuilder,
  });

  final String label;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggled;
  final String Function(String value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final value in options)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(labelBuilder != null ? labelBuilder!(value) : value),
                    showCheckmark: false,
                    selected: selected.contains(value),
                    onSelected: (_) => onToggled(value),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MultiSelectChips extends StatelessWidget {
  const _MultiSelectChips({
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggled,
    this.labelBuilder,
  });

  final String label;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggled;
  final String Function(String value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final value in options)
                FilterChip(
                  label: Text(labelBuilder != null ? labelBuilder!(value) : value),
                  showCheckmark: false,
                  selected: selected.contains(value),
                  onSelected: (_) => onToggled(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showBlockMultiSelectSheet(
  BuildContext context,
  WidgetRef ref,
  List<String> allBlocks,
) async {
  final filter = ref.read(productFilterProvider);
  final localSelected = {...filter.selectedBlocks};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: const Text('工区を選択'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              localSelected
                                ..clear()
                                ..addAll(allBlocks);
                            });
                          },
                          child: const Text('すべて選択'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => localSelected.clear());
                          },
                          child: const Text('選択解除'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allBlocks.length,
                      itemBuilder: (context, index) {
                        final block = allBlocks[index];
                        final isChecked = localSelected.contains(block);
                        return CheckboxListTile(
                          title: Text(block),
                          value: isChecked,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                localSelected.add(block);
                              } else {
                                localSelected.remove(block);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('キャンセル'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(productFilterProvider.notifier).setBlocks(localSelected);
                            Navigator.of(context).pop();
                          },
                          child: const Text('決定'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

class _SegmentFilterButton extends ConsumerWidget {
  const _SegmentFilterButton({
    required this.segments,
    required this.selected,
    required this.labelBuilder,
  });

  final List<String> segments;
  final Set<String> selected;
  final String Function(Set<String> selected) labelBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = labelBuilder(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '節',
          style:
              Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: () => _showSegmentMultiSelectSheet(context, ref, segments),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FloorFilterButton extends ConsumerWidget {
  const _FloorFilterButton({
    required this.floors,
    required this.selected,
    required this.labelBuilder,
  });

  final List<String> floors;
  final Set<String> selected;
  final String Function(Set<String> selected) labelBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = labelBuilder(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '階',
          style:
              Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: () => _showFloorMultiSelectSheet(context, ref, floors),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SectionFilterButton extends ConsumerWidget {
  const _SectionFilterButton({
    required this.sections,
    required this.selected,
    required this.labelBuilder,
  });

  final List<String> sections;
  final Set<String> selected;
  final String Function(Set<String> selected) labelBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = labelBuilder(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '断面',
          style:
              Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: () => _showSectionMultiSelectSheet(context, ref, sections),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

Future<void> _showSegmentMultiSelectSheet(
  BuildContext context,
  WidgetRef ref,
  List<String> segments,
) async {
  final filter = ref.read(productFilterProvider);
  final localSelected = {...filter.selectedSegments};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: const Text('節を選択'),
                    trailing: TextButton(
                      onPressed: () {
                        setState(() => localSelected.clear());
                      },
                      child: const Text('すべてクリア'),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: segments.length,
                      itemBuilder: (context, index) {
                        final seg = segments[index];
                        final isChecked = localSelected.contains(seg);
                        return CheckboxListTile(
                          title: Text(seg),
                          value: isChecked,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                localSelected.add(seg);
                              } else {
                                localSelected.remove(seg);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('キャンセル'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(productFilterProvider.notifier).setSegments(localSelected);
                            Navigator.of(context).pop();
                          },
                          child: const Text('決定'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

Future<void> _showFloorMultiSelectSheet(
  BuildContext context,
  WidgetRef ref,
  List<String> floors,
) async {
  final filter = ref.read(productFilterProvider);
  final localSelected = {...filter.selectedFloors};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: const Text('階を選択'),
                    trailing: TextButton(
                      onPressed: () {
                        setState(() => localSelected.clear());
                      },
                      child: const Text('すべてクリア'),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: floors.length,
                      itemBuilder: (context, index) {
                        final floor = floors[index];
                        final isChecked = localSelected.contains(floor);
                        return CheckboxListTile(
                          title: Text(floor),
                          value: isChecked,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                localSelected.add(floor);
                              } else {
                                localSelected.remove(floor);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('キャンセル'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(productFilterProvider.notifier).setFloors(localSelected);
                            Navigator.of(context).pop();
                          },
                          child: const Text('決定'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

Future<void> _showSectionMultiSelectSheet(
  BuildContext context,
  WidgetRef ref,
  List<String> sections,
) async {
  final filter = ref.read(productFilterProvider);
  final localSelected = {...filter.selectedSections};
  String keyword = '';
  final controller = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: StatefulBuilder(
            builder: (context, setState) {
              final filteredSections = sections
                  .where(
                    (s) => keyword.isEmpty ||
                        s.toLowerCase().contains(keyword.toLowerCase()),
                  )
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: const Text('断面を選択'),
                    trailing: TextButton(
                      onPressed: () {
                        setState(() => localSelected.clear());
                      },
                      child: const Text('すべてクリア'),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: '断面を検索 (例: H-400)',
                      ),
                      onChanged: (v) => setState(() => keyword = v.trim()),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredSections.length,
                      itemBuilder: (context, index) {
                        final section = filteredSections[index];
                        final isChecked = localSelected.contains(section);
                        return CheckboxListTile(
                          title: Text(section),
                          value: isChecked,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                localSelected.add(section);
                              } else {
                                localSelected.remove(section);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('キャンセル'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(productFilterProvider.notifier).setSections(localSelected);
                            Navigator.of(context).pop();
                          },
                          child: const Text('決定'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

class _ProductListView extends StatelessWidget {
  const _ProductListView({
    required this.displayProducts,
    required this.selectedProductId,
    required this.productProgressMap,
    required this.onSelectProduct,
  });

  final List<Product> displayProducts;
  final String? selectedProductId;
  final Map<String, GanttProduct> productProgressMap;
  final ValueChanged<Product> onSelectProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '製品（フィルタ結果）',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: displayProducts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = displayProducts[index];
              final isSelected = selectedProductId == product.id;
              final gantt = productProgressMap[product.id];
              final remainingCount =
                  gantt?.tasks.where((t) => t.progress < 1).length;
              // TODO: 今はPDFビューア動作確認のために先頭1件だけテストURLを使用している。
              //       本番では Product.drawingPdfUrl を正式に持たせて差し替えること。
              String? drawingUrl;
              try {
                final dynamicUrl = (product as dynamic).drawingPdfUrl;
                if (dynamicUrl is String && dynamicUrl.isNotEmpty) {
                  drawingUrl = dynamicUrl;
                }
              } catch (_) {
                drawingUrl = null;
              }
              drawingUrl ??= index == 0 ? kTestDrawingPdfUrl : null;
              final hasDrawing = drawingUrl != null && drawingUrl.isNotEmpty;
              final isPriority = product.overallEndDate != null &&
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
                    product.productCode.isNotEmpty
                        ? product.productCode
                        : product.name,
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
                          final sectionLabel =
                              product.section.isNotEmpty ? product.section : '-';
                          // TODO: 主材長さフィールド（例: product.mainLengthMm）を追加したら実値を表示する
                          const String? lengthMm = null;
                          final lengthLabel =
                              lengthMm != null ? '長さ: $lengthMm mm' : '長さ: -';
                          final remainingLabel = remainingCount != null
                              ? '残: $remainingCount'
                              : '残: ?';
                          final locationLabel = [
                            if (product.storyOrSet.isNotEmpty) '工区: ${product.storyOrSet}',
                            if (product.grid.isNotEmpty) '節: ${product.grid}',
                          ].join(' / ');
                          final line = [
                            '断面: $sectionLabel',
                            lengthLabel,
                            remainingLabel,
                            if (locationLabel.isNotEmpty) locationLabel,
                          ].join('   ');
                          return Text(
                            line,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
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
                  onTap: () => onSelectProduct(product),
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
          child: productsAsync.when(
            loading: () => Text(
              '選択中: 読み込み中',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            error: (e, _) => Text(
              '選択中: 読み込み失敗',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            data: (products) {
              final selectedProduct =
                  _findSelected(filteredProducts.isNotEmpty ? filteredProducts : products);
              return Text(
                selectedProduct != null
                    ? '選択中: ${selectedProduct.productCode.isNotEmpty ? selectedProduct.productCode : selectedProduct.name}'
                    : '選択中: 製品未選択',
                style: Theme.of(context).textTheme.titleMedium,
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ganttProductsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('工程の読み込みに失敗しました: $e')),
            data: (products) {
              if (selectedProductId == null) {
                return const Center(child: Text('製品を選択してください'));
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
                        ref.read(inspectionSelectedStepIdProvider.notifier).state =
                            task.stepId;
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
    ref.read(inspectionSelectedStepIdProvider.notifier).state = next.stepId;
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
      ref.read(inspectionSelectedStepIdProvider.notifier).state = sameStep.stepId;
    } else if (nextGanttProduct.tasks.isNotEmpty) {
      ref.read(inspectionSelectedStepIdProvider.notifier).state =
          nextGanttProduct.tasks.first.stepId;
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '製品: ${selectedProduct?.productCode.isNotEmpty == true ? selectedProduct!.productCode : selectedProduct?.name ?? '製品未選択'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '工程: ${currentTask?.stepLabel ?? currentTask?.name ?? '工程未選択'}',
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final requireNumbers = status == InspectionStatus.done;
              String? numberValidator(String? value) {
                if (!requireNumbers) return null;
                if (value == null || value.trim().isEmpty) {
                  return '必須です';
                }
                return double.tryParse(value.trim()) != null ? null : '数値を入力してください';
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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
                              final notifier = ref.read(inspectionStatusProvider.notifier);
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
                                        .state =
                                        mode;
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
                  onPressed: _isSaving
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
                  onPressed: _isSaving
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
