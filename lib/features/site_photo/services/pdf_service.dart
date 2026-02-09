// pdf_service.dart
// PDF生成サービス（Web対応版）
// 撮影済み写真を集めてA4縦・3段の工事写真台帳を作成

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets' as pw;
import 'package:printing/printing.dart';
import '../screens/site_photo_list_screen.dart';

/// PDF生成サービス
class PdfService {
  /// 工事写真台帳PDFを作成してプレビュー表示
  /// 
  /// [projectName] 工事名
  /// [items] 撮影済みの項目リスト
  static Future<void> createAndPreviewPdf(
    String projectName,
    List<PhotoItem> items,
  ) async {
    // === PDF プレビューを表示 ===
    await Printing.layoutPdf(
      onLayout: (format) async {
        return await _generatePdf(projectName, items);
      },
    );
  }

  /// PDFを生成
  /// 
  /// [projectName] 工事名
  /// [items] 撮影済みの項目リスト
  /// 
  /// 戻り値: PDF のバイトデータ
  static Future<Uint8List> _generatePdf(
    String projectName,
    List<PhotoItem> items,
  ) async {
    // === PDF ドキュメントを作成 ===
    final pdf = pw.Document();

    // === 日本語フォントを読み込み ===
    // printing パッケージの PdfGoogleFonts を使用して、
    // Google Fonts から Noto Sans JP を取得します。
    final font = await PdfGoogleFonts.notoSansJapaneseRegular();

    // === 各ページに3枚ずつ写真を配置 ===
    // MultiPage を使用すると、自動的にページ分割してくれます。
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4, // A4縦
        build: (context) {
          // 撮影済み項目をPDFアイテムに変換
          return items.map((item) {
            return _buildPhotoItem(
              projectName: projectName,
              item: item,
              font: font,
            );
          }).toList();
        },
      ),
    );

    // === PDF をバイトデータとして返す ===
    return pdf.save();
  }

  /// 1つの写真アイテムを構築
  /// 
  /// [projectName] 工事名
  /// [item] 撮影項目
  /// [font] 日本語フォント
  /// 
  /// 戻り値: PDF ウィジェット
  static pw.Widget _buildPhotoItem({
    required String projectName,
    required PhotoItem item,
    required pw.Font font,
  }) {
    // === 1ページに3枚収めるための高さ設定 ===
    // A4縦の高さは約842pt。
    // ヘッダー・フッター・余白を考慮すると、本文エリアは約750pt。
    // 750pt ÷ 3 = 250pt が1アイテムの最大高さ。
    // 余裕を持たせて230ptに設定します。
    const itemHeight = 230.0;

    return pw.Container(
      height: itemHeight,
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // === 左側: 写真（アスペクト比4:3） ===
          pw.Container(
            width: 280, // 4:3 のアスペクト比で高さ210ptに対応
            height: 210,
            margin: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: _buildPhotoImage(item, font),
          ),

          // === 右側: テキスト情報 ===
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 工事名
                  pw.Text(
                    '工事名',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    projectName,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // 工種
                  pw.Text(
                    '工種',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    item.name,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // 撮影日（ダミー）
                  pw.Text(
                    '撮影日',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '2026/02/09',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // 撮影者（ダミー）
                  pw.Text(
                    '撮影者',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'ユーザー名',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 写真画像を構築
  /// 
  /// Web の場合はダミー画像（緑色のコンテナ）、
  /// モバイルの場合は実際の画像を表示します。
  /// 
  /// [item] 撮影項目
  /// [font] 日本語フォント
  /// 
  /// 戻り値: PDF ウィジェット
  static pw.Widget _buildPhotoImage(PhotoItem item, pw.Font font) {
    // === Web の場合: ダミー画像（緑色のコンテナ） ===
    if (kIsWeb) {
      return pw.Container(
        color: PdfColors.green, // 緑色で塗りつぶし
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Webダミー',
                style: pw.TextStyle(
                  font: font,
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                item.name,
                style: pw.TextStyle(
                  font: font,
                  color: PdfColors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // === モバイルの場合: 実際の画像を読み込み ===
    // TODO: 実機では File(item.imagePath) から画像を読み込んで表示
    // 例: final imageBytes = await File(item.imagePath).readAsBytes();
    //     final image = pw.MemoryImage(imageBytes);
    //     return pw.Image(image, fit: pw.BoxFit.cover);

    return pw.Container(
      color: PdfColors.grey300,
      child: pw.Center(
        child: pw.Text(
          '画像読み込み\n（実機対応予定）',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: font,
            color: PdfColors.grey700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
