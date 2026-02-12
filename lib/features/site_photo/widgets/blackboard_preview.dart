// blackboard_preview.dart
// 共通黒板プレビューウィジェット
// コンテンツロジック（文字生成・フォントサイズ計算）を担当
// デザイン定義は blackboard_frame.dart に委譲

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'blackboard_frame.dart'; // デザイン定義

/// 黒板プレビューウィジェット
class BlackboardPreview extends StatelessWidget {
  /// 工事名
  final String projectName;

  /// 工種（カテゴリー）
  final String category;

  /// 種別
  final String constructionType;

  /// 撮影者
  final String photographer;

  /// 黒板タイプ ('type2' | 'type3' | 'type4' | 'typeDetail')
  final String blackboardType;

  /// フリースペースに表示するテキスト（複数行対応）
  final String? freeSpaceText;

  /// 撮影日の表示有無
  final bool showDate;

  /// 撮影日（nullの場合は今日の日付）
  final DateTime? date;

  const BlackboardPreview({
    super.key,
    required this.projectName,
    this.category = '',
    this.constructionType = '',
    this.photographer = '',
    this.blackboardType = 'type2',
    this.freeSpaceText,
    this.showDate = true,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    // 1. テキスト生成ロジック
    final displayContent = _getFreeSpaceText();
    
    // 2. フォントサイズ計算ロジック（行数ベース）
    final lineCount = _countLines(displayContent);
    final style = _getStyleForLineCount(lineCount);

    final dateStr = DateFormat('yyyy/MM/dd').format(date ?? DateTime.now());

    // 3. 表示（フレームを使用）
    return BlackboardFrame(
      projectName: projectName,
      categoryName: category, // 工種はフレーム側の固定ヘッダーに渡す
      child: Stack(
        children: [
          // メインテキスト（フリースペース）
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.all(style.padding),
              alignment: Alignment.topLeft,
              child: Text(
                displayContent,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: style.fontSize,
                  height: style.lineHeight,
                ),
              ),
            ),
          ),
          // 撮影日（右下）
          if (showDate)
            Positioned(
              bottom: 8,
              right: 8,
              child: Text(
                dateStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// フリースペースのテキストを取得
  String _getFreeSpaceText() {
    final buffer = StringBuffer();

    // 種別（Construction Type）は中段行から削除されたため、
    // ここでフリースペースの先頭に表示するか、あるいは呼び出し元で結合されている想定
    // Current Logic: 呼び出し元で結合されていない場合、種別を表示するニーズがある場合はここで結合
    // しかし、ユーザーのスクリーンショット（2行ヘッダー）では種別行がなく、
    // フリースペースに「工程：〇〇」「作業名：〇〇」とある。
    // ここでは単純に freeSpaceText を優先し、なければ撮影者を表示するロジックとする
    // ※呼び出し元が category/type を含めたテキストを freeSpaceText に渡している前提
    
    // 4. フリースペースの生成ロジック改善
    // constructionType がある場合は、それを優先的に表示する（ユーザー要望のレイアウト準拠）
    if (freeSpaceText != null && freeSpaceText!.isNotEmpty) {
      buffer.write(freeSpaceText!);
    } else {
      // 呼び出し元で指定がない場合、constructionType（種別）を表示
      if (constructionType.isNotEmpty) {
        buffer.writeln('種別：$constructionType');
      }
      
      // 撮影者
      if (photographer.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln(); // 空行を入れるか、改行のみか
        buffer.write('撮影者：$photographer');
      }
    }
    
    return buffer.toString().trimRight();
  }

  /// テキストの行数をカウント
  int _countLines(String text) {
    if (text.isEmpty) return 0;
    return text.split('\n').length;
  }

  /// 行数に応じたスタイルを取得
  _FreeSpaceStyle _getStyleForLineCount(int lineCount) {
    if (lineCount <= 2) {
      return const _FreeSpaceStyle(fontSize: 24.0, lineHeight: 1.5, padding: 16.0);
    } else if (lineCount <= 4) {
      return const _FreeSpaceStyle(fontSize: 18.0, lineHeight: 1.4, padding: 12.0);
    } else {
      return const _FreeSpaceStyle(fontSize: 14.0, lineHeight: 1.2, padding: 8.0);
    }
  }
}

/// フリースペースのスタイル情報
class _FreeSpaceStyle {
  final double fontSize;
  final double lineHeight;
  final double padding;

  const _FreeSpaceStyle({
    required this.fontSize,
    required this.lineHeight,
    required this.padding,
  });
}
