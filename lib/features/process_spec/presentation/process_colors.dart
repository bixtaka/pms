import 'package:flutter/material.dart';

/// SPEC.md に定義された工程（process_groups / process_steps）に対する公式カラー設定
/// - グループ名・工程名は SPEC のラベルをそのままキーにする
/// - 未定義ラベルはグレーでフォールバック
class ProcessColors {
  static const _groupColors = <String, Color>{
    '一次加工': Color(0xFF1565C0), // Blue 800
    'コア部': Color(0xFF283593), // Indigo 800
    '仕口部': Color(0xFF00897B), // Teal 600
    '大組部': Color(0xFF2E7D32), // Green 700
    '二次部材': Color(0xFF9E9D24), // Lime 800
    '製品検査': Color(0xFFF57C00), // Orange 700
    '製品塗装': Color(0xFFD81B60), // Pink 600
    '積込': Color(0xFFFFA000), // Amber 700
    '出荷': Color(0xFF6D4C41), // Brown 600
  };

  static const _stepColors = <String, Color>{
    '切断': Color(0xFF1976D2),
    '孔あけ': Color(0xFF00BCD4),
    '開先加工': Color(0xFF00897B),
    'ショットブラスト': Color(0xFF303F9F),
    '罫書': Color(0xFF5E35B1),
    '組立': Color(0xFF388E3C),
    '溶接': Color(0xFFE64A19),
    'UT': Color(0xFFD32F2F),
    '寸法検査': Color(0xFFFFB300),
    '塗装': Color(0xFFD81B60),
  };

  /// グループラベルからカラーを取得（SPEC ラベルのみ）
  static Color groupByLabel(String? label) {
    if (label == null || label.isEmpty) return Colors.grey;
    return _groupColors[label] ?? Colors.grey;
  }

  /// 工程ラベルからカラーを取得（SPEC ラベルのみ）
  static Color stepByLabel(String? label) {
    if (label == null || label.isEmpty) return Colors.grey;
    return _stepColors[label] ?? Colors.grey;
  }

  /// グループ・工程のラベルからカラーを決定
  /// - stepLabel 優先、無ければ groupLabel を見る
  static Color fromLabels({String? stepLabel, String? groupLabel}) {
    final step = stepByLabel(stepLabel);
    if (step != Colors.grey) return step;
    return groupByLabel(groupLabel);
  }

  /// 既存コードの type ベースカラーを置き換えるためのヘルパー
  static Color fromProcessNames(String label) =>
      fromLabels(stepLabel: label, groupLabel: label);
}
