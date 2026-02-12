import 'package:flutter/material.dart';

/// 【変更禁止】黒板の共通デザインフレーム
/// 枠線、背景色、ヘッダーレイアウトを定義。
/// 内部のコンテンツロジック変更時はこのファイルを触らず、呼び出し元を修正すること。
class BlackboardFrame extends StatelessWidget {
  final String projectName;
  final String categoryName; // 工種（カテゴリー）
  final Widget child; // フリースペースに表示するウィジェット

  const BlackboardFrame({
    super.key,
    required this.projectName,
    required this.categoryName, // 工種も固定ヘッダーとして扱う
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // デザイン定数（変更禁止）
    const blackboardColor = Color(0xFF00552E); // 濃い緑
    const borderColor = Colors.white;
    const double borderWidth = 2.0; // 枠線幅 2.0
    const double paddingWidth = 2.0; // 緑色の余白 2.0

    // テキストスタイル（変更禁止）
    const headerStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16.0,
    );

    // 外枠（緑の余白）
    return Container(
      decoration: BoxDecoration(
        color: blackboardColor,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(paddingWidth), // 緑の余白
      
      // 内枠（白枠）
      child: Container(
        decoration: BoxDecoration(
          color: blackboardColor,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          children: [
            // --- 上段：工事名（固定） ---
            _buildHeaderRow('工事名', projectName, headerStyle, borderColor, borderWidth),
            // 区切り線
            Divider(color: borderColor, height: borderWidth, thickness: borderWidth),

            // --- 中段：工種（固定） ---
            _buildHeaderRow('工　種', categoryName, headerStyle, borderColor, borderWidth),
            // 区切り線
            Divider(color: borderColor, height: borderWidth, thickness: borderWidth),

            // --- 下段：フリースペース（可変） ---
            Expanded(
              child: child, // ここに外部からコンテンツを注入
            ),
          ],
        ),
      ),
    );
  }

  /// ヘッダー行の構築
  Widget _buildHeaderRow(String label, String value, TextStyle style, Color borderColor, double borderWidth) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // ラベル (30%)
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: borderColor, width: borderWidth),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: style),
              ),
            ),
          ),
          // 値 (70%)
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: style,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
