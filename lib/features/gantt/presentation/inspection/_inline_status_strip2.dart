part of '../gantt_screen.dart';

class _InlineStatusStrip2 extends StatefulWidget {
  const _InlineStatusStrip2({
    required this.steps,
    required this.groups,
    required this.statusByStep,
    required this.latestByStep,
    required this.groupLabels,
  });

  final List<ProcessStep> steps;
  final List<ProcessGroup> groups;
  final Map<String, ProcessCellStatus>? statusByStep;
  final Map<String, ProcessProgressDaily>? latestByStep;
  final Map<String, String> groupLabels;

  @override
  State<_InlineStatusStrip2> createState() => _InlineStatusStrip2State();
}

class _InlineStatusStrip2State extends State<_InlineStatusStrip2> {
  final ScrollController _hCtrl = ScrollController();
  bool _logged = false;

  @override
  void dispose() {
    _hCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final groups = widget.groups;
    if (steps.isEmpty) return const SizedBox.shrink();
    const double cellWidth = 44;
    const double spacing = 4;

    final grouped = <String, List<ProcessStep>>{};
    const othersKey = '_others';
    for (final s in steps) {
      final key = (s.groupId.isNotEmpty) ? s.groupId : othersKey;
      grouped.putIfAbsent(key, () => <ProcessStep>[]).add(s);
    }

    final groupOrder = <String>[];
    if (groups.isNotEmpty) {
      for (final g in groups) {
        if (grouped.containsKey(g.id)) {
          groupOrder.add(g.id);
        }
      }
      final remaining = grouped.keys.toSet()..removeAll(groupOrder);
      if (remaining.contains(othersKey)) {
        groupOrder.add(othersKey);
        remaining.remove(othersKey);
      }
      for (final key in remaining) {
        groupOrder.add(key);
      }
    } else {
      groupOrder.addAll(grouped.keys.toList()
        ..sort((a, b) {
          final aFirst = grouped[a]!.first.sortOrder;
          final bFirst = grouped[b]!.first.sortOrder;
          return aFirst.compareTo(bFirst);
        }));
    }

    final headerCells = <Widget>[];
    final childCells = <Widget>[];
    double totalWidth = 0;

    for (final gid in groupOrder) {
      final children = grouped[gid]!;
      children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final width = children.length * cellWidth + spacing * (children.length - 1);
      totalWidth += width;
      headerCells.add(
        Container(
          width: width,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            widget.groupLabels[gid] ?? (gid == othersKey ? 'その他' : gid),
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      for (final step in children) {
        final status = widget.statusByStep?[step.id] ?? ProcessCellStatus.notStarted;
        final color = _processCellStatusColor(status);
        final label = step.label.length > 2 ? step.label.substring(0, 2) : step.label;
        childCells.add(
          InkWell(
            onTap: () =>
                _showProgressDetailDialog(context, step, widget.latestByStep?[step.id], status),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: cellWidth,
              margin: EdgeInsets.only(right: spacing),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                border: Border.all(color: color, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
    }

    return SizedBox(
      height: 48,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (kDebugMode && !_logged) {
            _logged = true;
            debugPrint(
                '[strip2] viewport=${constraints.maxWidth}, totalWidth=$totalWidth, cells=${childCells.length}, cellWidth=$cellWidth');
          }
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              if (!_hCtrl.hasClients) return;
              final max = _hCtrl.position.maxScrollExtent;
              final next = (_hCtrl.offset - details.delta.dx).clamp(0.0, max);
              _hCtrl.jumpTo(next);
            },
            child: SingleChildScrollView(
              controller: _hCtrl,
              scrollDirection: Axis.horizontal,
              primary: false,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: totalWidth > 0 ? totalWidth : constraints.maxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: headerCells),
                    const SizedBox(height: 4),
                    Row(children: childCells),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
