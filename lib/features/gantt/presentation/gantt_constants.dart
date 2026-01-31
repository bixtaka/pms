import 'package:flutter/material.dart';

/// ガントチャート用の定数定義
///
/// gantt_screen.dart から抽出した定数群。
/// 行高さ、幅、色、バーサイズなどの共通設定。

// ガント行高さを左右で揃える共通定数
const double kGanttRowHeight = 44.0;
const double kGanttLeftPaneWidth = 280.0;
const double kGanttProcessStepIndent = 24.0;

// ズームレベル設定
const List<double> kGanttDayZoomLevels = [32.0, 48.0, 64.0];
const double kGanttMinScaleDayWidth = 16.0;
const double kGanttMaxScaleDayWidth = 40.0;

// タイムラインパディング
const int kDayViewPaddingAfterDays = 21; // 日ビュー専用の表示余白（日数）
const int kTimelinePaddingDaysBefore = 7;
const int kTimelinePaddingDaysAfter = 7;
const int kTimelineExtraScrollableDays = 14;

// ミニマップ
const double kMiniMapDayWidth = 3.0;
const double kMiniMapHeight = 40.0;

// バーの色
// バーの色 (Apple-style Modern Palette)
const Color kGanttPlannedBarColor = Color(0xFFE5E5EA);  // System Grey 5 (Light Mode) - 背景フレーム感
const Color kGanttPlannedBarBorderColor = Colors.transparent; // ボーダーなし（背景色で表現）
const Color kGanttActualInProgressColor = Color(0xFFFF9500);  // System Orange - 視認性の高いオレンジ
const Color kGanttActualDoneColor = Color(0xFF34C759);  // System Green - 安心感のある緑

// バーのサイズ
const double kGanttPlannedBarHeight = 24.0;  // 角丸12pxを綺麗に見せるため高さ確保
const double kGanttActualBarHeight = 12.0;   // 計画バーの中に収まるサイズ（上下6pxパディング相当）
const double kGanttPlannedBarRadius = 12.0;  // ユーザー指定: 12px
const double kGanttActualBarRadius = 6.0;    // 内部バーは少し小さめの角丸
const double kGanttActualBarMinWidth = 12.0; // 最小幅
const double kGanttPlannedBarBorderWidth = 0.0;

// タイムラインヘッダー
const double kTimelineMonthRowHeight = 18.0;
const double kTimelineDayRowHeight = 18.0;
const double kProcessGroupRowHeight = 60.0;

// TODO: テスト用。あとで正式な drawingPdfUrl に置き換えること。
// const String kTestDrawingPdfUrl =
//     'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
