import 'dart:math';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class WorkTypeGanttWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final totalDays = endDate.difference(startDate).inDays + 1;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32 - 150; // パディングと工種名幅を除く
    final cellWidth = availableWidth / totalDays;
    final chartWidth = max(
      totalDays * cellWidth + 150,
      screenWidth,
    ); // 画面幅以上になるように
    final rowHeight = 50.0;

    return Container(
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
              // 本体
              ...processList.map((processName) {
                final data = workTypeData.firstWhere(
                  (d) => d.type == processName,
                  orElse: () => WorkTypeGanttData(
                    type: processName,
                    averageStartDate: null,
                    averageEndDate: null,
                    totalCount: 0,
                    completedCount: 0,
                    completionRate: 0.0,
                  ),
                );
                return SizedBox(
                  width: chartWidth,
                  height: rowHeight,
                  child: _buildWorkTypeRow(
                    data,
                    totalDays,
                    rowHeight,
                    cellWidth,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
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
            final currentDate = startDate.add(Duration(days: index));
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
      final startOffset = data.averageStartDate!.difference(startDate).inDays;
      final duration =
          data.averageEndDate!.difference(data.averageStartDate!).inDays + 1;
      if (startOffset >= 0 && startOffset < totalDays) {
        barStart = startOffset * cellWidth;
        barWidth = duration * cellWidth;
      }
    } else if (data.averageStartDate != null) {
      // 開始日のみ設定されている場合
      final startOffset = data.averageStartDate!.difference(startDate).inDays;
      if (startOffset >= 0 && startOffset < totalDays) {
        barStart = startOffset * cellWidth;
        barWidth = cellWidth;
      }
    }

    // バーのテキストを設定
    barText = '${data.completedCount}/${data.totalCount}';

    return Row(
      children: [
        // 工種名
        Container(
          width: 150,
          height: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.type,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '完了率: ${data.completionRate.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
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
                        color: Colors.black.withOpacity(0.08),
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
}
