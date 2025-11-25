import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

// ignore_for_file: unused_local_variable

class WorkTypeGanttWidget extends StatefulWidget {
  final List<WorkTypeGanttData> workTypeData;
  final List<String> processList;
  final DateTime startDate;
  final DateTime endDate;

  const WorkTypeGanttWidget({
    super.key,
    required this.workTypeData,
    required this.processList,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<WorkTypeGanttWidget> createState() => _WorkTypeGanttWidgetState();
}

class _WorkTypeGanttWidgetState extends State<WorkTypeGanttWidget> {
  bool isCoreExpanded = false;
  bool isShikuchiExpanded = false;
  bool isOogumiExpanded = false;
  bool isNijiExpanded = false;

  // 親工種ごとに計画バーの開始日・終了日をローカルStateで管理
  Map<String, DateTime> planStartDates = {};
  Map<String, DateTime> planEndDates = {};
  // ドラッグ中の親工種名
  String? draggingPlan;
  // ドラッグ開始時のオフセット
  double dragStartX = 0;
  DateTime? dragInitialStart;
  DateTime? dragInitialEnd;

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.endDate.difference(widget.startDate).inDays + 1;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32 - 150;
    final cellWidth = availableWidth / totalDays;
    final chartWidth = (totalDays * cellWidth + 150).clamp(
      screenWidth,
      double.infinity,
    );
    final rowHeight = 50.0;

    // 計画バーの初期値（仮：全体期間の1/3〜2/3）
    void ensurePlanDates(String type) {
      if (!planStartDates.containsKey(type)) {
        planStartDates[type] = widget.startDate.add(
          Duration(days: (totalDays / 3).floor()),
        );
        planEndDates[type] = widget.startDate.add(
          Duration(days: (totalDays * 2 / 3).floor()),
        );
      }
    }

    // 親工種リストを定義（コア・仕口のみ表示）
    final parentProcessList = [
      'コア',
      '仕口',
      '大組み',
      '二次部材',
      ...widget.processList.where(
        (p) =>
            p != 'コア組立' &&
            p != 'コア溶接' &&
            p != 'コアＵＴ' &&
            p != '仕口組立' &&
            p != '仕口検品' &&
            p != '仕口溶接' &&
            p != '仕口仕上げ' &&
            p != '仕口ＵＴ' &&
            p != '柱組立' &&
            p != '柱溶接' &&
            p != '柱仕上げ' &&
            p != '柱ＵＴ' &&
            p != '二次部材組立' &&
            p != '二次部材検品' &&
            p != '二次部材溶接' &&
            p != '仕上げ',
      ),
    ];
    final coreTypes = ['コア組立', 'コア溶接', 'コアＵＴ'];
    final shikuchiTypes = ['仕口組立', '仕口検品', '仕口溶接', '仕口仕上げ', '仕口ＵＴ'];
    final oogumiTypes = ['柱組立', '柱溶接', '柱仕上げ', '柱ＵＴ'];
    final nijiTypes = ['二次部材組立', '二次部材検品', '二次部材溶接', '仕上げ'];
    int extraRows =
        (isCoreExpanded ? coreTypes.length : 0) +
        (isShikuchiExpanded ? shikuchiTypes.length : 0) +
        (isOogumiExpanded ? oogumiTypes.length : 0) +
        (isNijiExpanded ? nijiTypes.length : 0);

    final parentTypes = ['コア', '仕口', '大組み', '二次部材'];
    final childTypeMap = {
      'コア': ['コア組立', 'コア溶接', 'コアＵＴ'],
      '仕口': ['仕口組立', '仕口検品', '仕口溶接', '仕口仕上げ', '仕口ＵＴ'],
      '大組み': ['柱組立', '柱溶接', '柱仕上げ', '柱ＵＴ'],
      '二次部材': ['二次部材組立', '二次部材検品', '二次部材溶接', '仕上げ'],
    };
    final allChildTypes = childTypeMap.values.expand((v) => v).toSet();
    final singleTypes = widget.processList
        .where((p) => !allChildTypes.contains(p))
        .toList();

    // 表示用リストを作成（親子展開状態を考慮）
    List<Map<String, dynamic>> displayRows = [];
    for (final parent in parentTypes) {
      displayRows.add({'type': parent, 'isParent': true});
      bool expanded = false;
      switch (parent) {
        case 'コア':
          expanded = isCoreExpanded;
          break;
        case '仕口':
          expanded = isShikuchiExpanded;
          break;
        case '大組み':
          expanded = isOogumiExpanded;
          break;
        case '二次部材':
          expanded = isNijiExpanded;
          break;
      }
      if (expanded) {
        for (final child in childTypeMap[parent] ?? []) {
          displayRows.add({'type': child, 'isChild': true, 'parent': parent});
        }
      }
    }
    for (final single in singleTypes) {
      // 親子でない工種
      if (!parentTypes.contains(single)) {
        displayRows.add({'type': single, 'isSingle': true});
      }
    }

    return Column(
      children: [
        // 元のガントチャート
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: Column(
                  children: [
                    // ヘッダー
                    SizedBox(
                      width: chartWidth,
                      height: 44,
                      child: _buildHeader(totalDays, cellWidth),
                    ),
                    // 本体（縦スクロール対応）
                    Expanded(
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayRows.length,
                        itemBuilder: (context, index) {
                          final row = displayRows[index];
                          final type = row['type'] as String;
                          ensurePlanDates(type);
                          final data = widget.workTypeData.firstWhere(
                            (d) => d.type == type,
                            orElse: () => WorkTypeGanttData(
                              type: type,
                              averageStartDate: null,
                              averageEndDate: null,
                              totalCount: 0,
                              completedCount: 0,
                              completionRate: 0.0,
                            ),
                          );
                          if (row['isParent'] == true) {
                            // 1. 親工種行
                            return SizedBox(
                              width: chartWidth,
                              height: rowHeight,
                              child: Row(
                                children: [
                                  Container(
                                    width: 150,
                                    height: double.infinity,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          type,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            (() {
                                              switch (type) {
                                                case 'コア':
                                                  return isCoreExpanded
                                                      ? Icons.expand_less
                                                      : Icons.expand_more;
                                                case '仕口':
                                                  return isShikuchiExpanded
                                                      ? Icons.expand_less
                                                      : Icons.expand_more;
                                                case '大組み':
                                                  return isOogumiExpanded
                                                      ? Icons.expand_less
                                                      : Icons.expand_more;
                                                case '二次部材':
                                                  return isNijiExpanded
                                                      ? Icons.expand_less
                                                      : Icons.expand_more;
                                                default:
                                                  return Icons.expand_more;
                                              }
                                            })(),
                                          ),
                                          iconSize: 18,
                                          onPressed: () {
                                            setState(() {
                                              switch (type) {
                                                case 'コア':
                                                  isCoreExpanded =
                                                      !isCoreExpanded;
                                                  break;
                                                case '仕口':
                                                  isShikuchiExpanded =
                                                      !isShikuchiExpanded;
                                                  break;
                                                case '大組み':
                                                  isOogumiExpanded =
                                                      !isOogumiExpanded;
                                                  break;
                                                case '二次部材':
                                                  isNijiExpanded =
                                                      !isNijiExpanded;
                                                  break;
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    fit: FlexFit.tight,
                                    child: Stack(
                                      children: [
                                        _buildWorkTypeRow(
                                          data,
                                          totalDays,
                                          rowHeight,
                                          cellWidth,
                                        ),
                                        _buildPlanBar(
                                          type,
                                          planStartDates[type]!,
                                          planEndDates[type]!,
                                          totalDays,
                                          cellWidth,
                                          rowHeight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (row['isChild'] == true) {
                            // 2. 親子でない工種行
                            return SizedBox(
                              width: chartWidth,
                              height: rowHeight,
                              child: Row(
                                children: [
                                  Container(
                                    width: 150,
                                    height: double.infinity,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      type,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    fit: FlexFit.tight,
                                    child: Stack(
                                      children: [
                                        _buildWorkTypeRow(
                                          data,
                                          totalDays,
                                          rowHeight,
                                          cellWidth,
                                        ),
                                        _buildPlanBar(
                                          type,
                                          planStartDates[type]!,
                                          planEndDates[type]!,
                                          totalDays,
                                          cellWidth,
                                          rowHeight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // 3. 親子でない工種（単独行：計画バー＋実績バー）
                            return SizedBox(
                              width: chartWidth,
                              height: rowHeight,
                              child: Row(
                                children: [
                                  Container(
                                    width: 150,
                                    height: double.infinity,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      type,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    fit: FlexFit.tight,
                                    child: Stack(
                                      children: [
                                        _buildWorkTypeRow(
                                          data,
                                          totalDays,
                                          rowHeight,
                                          cellWidth,
                                        ),
                                        _buildPlanBar(
                                          type,
                                          planStartDates[type]!,
                                          planEndDates[type]!,
                                          totalDays,
                                          cellWidth,
                                          rowHeight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 計画バーWidget（ドラッグで編集可能な仮UI）
  Widget _buildPlanBar(
    String type,
    DateTime start,
    DateTime end,
    int totalDays,
    double cellWidth,
    double rowHeight,
  ) {
    final barStart =
        planStartDates[type]!.difference(widget.startDate).inDays * cellWidth;
    final barWidth =
        (planEndDates[type]!.difference(planStartDates[type]!).inDays + 1) *
        cellWidth;

    return Stack(
      children: [
        // 計画バー本体
        Positioned(
          left: barStart,
          top: 6,
          child: GestureDetector(
            onTap: () {
              _showSfDateRangePicker(context, type);
            },
            child: Container(
              width: barWidth,
              height: rowHeight - 12,
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha((0.2 * 255).round()),
                border: Border.all(color: Colors.blue, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '計画',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // コンパクトな日付選択ダイアログ
  // ignore: unused_element
  void _showCompactDatePicker(BuildContext context, String type) {
    DateTime selectedStart = planStartDates[type]!;
    DateTime selectedEnd = planEndDates[type]!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$type の計画期間を設定'),
          content: SizedBox(
            width: 300,
            height: 200,
            child: Column(
              children: [
                // 開始日選択
                ListTile(
                  title: const Text('開始日'),
                  subtitle: Text(
                    '${selectedStart.year}/${selectedStart.month}/${selectedStart.day}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedStart,
                      firstDate: widget.startDate,
                      lastDate: widget.endDate,
                    );
                    if (picked != null) {
                      selectedStart = picked;
                      if (selectedStart.isAfter(selectedEnd)) {
                        selectedEnd = selectedStart;
                      }
                    }
                  },
                ),
                // 終了日選択
                ListTile(
                  title: const Text('終了日'),
                  subtitle: Text(
                    '${selectedEnd.year}/${selectedEnd.month}/${selectedEnd.day}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedEnd,
                      firstDate: selectedStart,
                      lastDate: widget.endDate,
                    );
                    if (picked != null) {
                      selectedEnd = picked;
                    }
                  },
                ),
                const SizedBox(height: 20),
                // 期間表示
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '期間: ${selectedEnd.difference(selectedStart).inDays + 1}日間',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  planStartDates[type] = selectedStart;
                  planEndDates[type] = selectedEnd;
                  debugPrint(
                    'New plan: start: ${planStartDates[type]}, end: ${planEndDates[type]}',
                  );
                });
                Navigator.of(context).pop();
              },
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
  }

  // 完了率に応じた色を取得
  Color _getCompletionColor(double completionRate) {
    if (completionRate >= 80) {
      return Colors.green;
    } else if (completionRate >= 30) {
      return Colors.blue;
    } else {
      return Colors.grey.shade400;
    }
  }

  // 日付表示フォーマットを動的に調整
  String _getDateDisplay(DateTime date, int totalDays) {
    if (totalDays <= 7) {
      return '${date.month}/${date.day}';
    } else if (totalDays <= 30) {
      return '${date.day}';
    } else if (totalDays <= 90) {
      // 3か月以内は週単位で表示
      final weekDay = date.weekday;
      if (weekDay == 1) {
        // 月曜日
        return '${date.month}/${date.day}';
      } else {
        return '${date.day}';
      }
    } else {
      // 6か月は月単位で表示
      final day = date.day;
      if (day == 1) {
        // 月初
        return '${date.month}月';
      } else if (day == 15) {
        // 月中
        return '${date.day}';
      } else {
        return '';
      }
    }
  }

  // ヘッダー部分
  Widget _buildHeader(int totalDays, double cellWidth) {
    return Row(
      children: [
        // 工種名ヘッダー
        Container(
          width: 150,
          height: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: const Text(
            '工種名',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        // 日付ヘッダー
        Row(
          children: List.generate(totalDays, (index) {
            final currentDate = widget.startDate.add(Duration(days: index));
            final dateText = _getDateDisplay(currentDate, totalDays);

            // 空文字の場合は表示しない
            if (dateText.isEmpty) {
              return Container(
                width: cellWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              );
            }

            return Container(
              width: cellWidth,
              height: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (totalDays <= 7)
                    Text(
                      '${currentDate.month}/${currentDate.day}',
                      style: const TextStyle(fontSize: 8),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // 工種別ガントチャート行
  Widget _buildWorkTypeRow(
    WorkTypeGanttData data,
    int totalDays,
    double rowHeight,
    double cellWidth,
  ) {
    // 進捗バーの位置と幅を計算
    double barStart = 0;
    double barWidth = 0;
    Color barColor = _getCompletionColor(data.completionRate);
    String barText = '';

    if (data.averageStartDate != null && data.averageEndDate != null) {
      // 平均開始日と終了日が設定されている場合
      final startOffset = data.averageStartDate!
          .difference(widget.startDate)
          .inDays;
      final duration =
          data.averageEndDate!.difference(data.averageStartDate!).inDays + 1;
      if (startOffset >= 0 && startOffset < totalDays) {
        barStart = startOffset * cellWidth;
        barWidth = duration * cellWidth;
      }
    } else if (data.averageStartDate != null) {
      // 開始日のみ設定されている場合
      final startOffset = data.averageStartDate!
          .difference(widget.startDate)
          .inDays;
      if (startOffset >= 0 && startOffset < totalDays) {
        barStart = startOffset * cellWidth;
        barWidth = cellWidth;
      }
    }

    // バーのテキストを設定
    barText = '${data.completedCount}/${data.totalCount}';

    return Row(
      children: [
        // ガントチャートバー＋グリッド
        Stack(
          children: [
            // 背景グリッド
            Row(
              children: List.generate(
                totalDays,
                (index) => Container(
                  width: cellWidth,
                  height: rowHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade100),
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ),
            // 進捗バー
            if (data.averageStartDate != null)
              Positioned(
                left: barStart,
                top: 6,
                child: Container(
                  width: barWidth,
                  height: rowHeight - 12,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.08 * 255).round()),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      barText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            // 開始日がない場合は薄いグレーで表示
            if (data.averageStartDate == null)
              Positioned(
                left: 0,
                top: 6,
                child: Container(
                  width: cellWidth,
                  height: rowHeight - 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      '未着手',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // 日付のみを返すユーティリティ関数
  DateTime _toDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void _showSfDateRangePicker(BuildContext context, String type) {
    DateTimeRange? tempRange = DateTimeRange(
      start: planStartDates[type]!,
      end: planEndDates[type]!,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$type の計画期間を設定'),
          content: SizedBox(
            width: 320,
            height: 350,
            child: SfDateRangePicker(
              selectionMode: DateRangePickerSelectionMode.range,
              initialSelectedRange: PickerDateRange(
                planStartDates[type]!,
                planEndDates[type]!,
              ),
              minDate: widget.startDate,
              maxDate: widget.endDate,
              onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                if (args.value is PickerDateRange) {
                  final range = args.value as PickerDateRange;
                  if (range.startDate != null && range.endDate != null) {
                    tempRange = DateTimeRange(
                      start: _toDateOnly(range.startDate!),
                      end: _toDateOnly(range.endDate!),
                    );
                  }
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (tempRange != null) {
                  setState(() {
                    planStartDates[type] = _toDateOnly(
                      tempRange!.start.add(const Duration(days: 1)),
                    );
                    planEndDates[type] = _toDateOnly(
                      tempRange!.end.add(const Duration(days: 1)),
                    );
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
  }
}
