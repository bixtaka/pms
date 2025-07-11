import 'package:flutter/material.dart';
import '../models/product.dart';

class GanttChartWidget extends StatelessWidget {
  final List<Product> products;
  final DateTime startDate;
  final DateTime endDate;

  const GanttChartWidget({
    Key? key,
    required this.products,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalDays = endDate.difference(startDate).inDays + 1;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32 - 150; // パディングと製品名幅を除く
    final cellWidth = availableWidth / totalDays;
    final chartWidth = totalDays * cellWidth + 150;
    final rowHeight = 44.0;

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
              ...products.map(
                (product) => SizedBox(
                  width: chartWidth,
                  height: rowHeight,
                  child: _buildGanttRow(
                    product,
                    totalDays,
                    rowHeight,
                    cellWidth,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        // 製品名ヘッダー
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
            '製品名',
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

  // ガントチャート行
  Widget _buildGanttRow(
    Product product,
    int totalDays,
    double rowHeight,
    double cellWidth,
  ) {
    // 進捗バーの位置と幅を計算
    double barStart = 0;
    double barWidth = 0;
    Color barColor = Colors.grey.shade400;
    String barText = '';

    if (product.startDate != null && product.endDate != null) {
      // 開始日と終了日が設定されている場合
      final startOffset = product.startDate!.difference(startDate).inDays;
      final duration =
          product.endDate!.difference(product.startDate!).inDays + 1;
      if (startOffset >= 0 && startOffset < totalDays) {
        barStart = startOffset * cellWidth;
        barWidth = duration * cellWidth;
      }
    } else if (product.status == 'in_progress' && product.startDate != null) {
      // 作業中で開始日のみ設定されている場合
      final startOffset = product.startDate!.difference(startDate).inDays;
      if (startOffset >= 0 && startOffset < totalDays) {
        barStart = startOffset * cellWidth;
        barWidth = cellWidth;
      }
    }

    // 状態に応じて色とテキストを設定
    switch (product.status) {
      case 'completed':
        barColor = Colors.green;
        barText = '完了';
        break;
      case 'in_progress':
        barColor = Colors.blue;
        barText = '作業中';
        break;
      case 'not_started':
        barColor = Colors.grey.shade400;
        barText = '未着手';
        break;
    }

    return Row(
      children: [
        // 製品名
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
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                product.type,
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
            if (product.status != 'not_started' ||
                (product.startDate != null && product.endDate != null))
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
            // 未着手の場合は薄いグレーで表示
            if (product.status == 'not_started' &&
                product.startDate == null &&
                product.endDate == null)
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
