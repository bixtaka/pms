import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportCoverBuilder {
  /// 共通の表紙ページを生成する
  static Future<pw.Page> buildCommonCover({
    required String projectName,
    required String reportTitle,
    required String companyName,
    DateTime? inspectionDate,
    String? inspectorName,
  }) async {
    // 1. フォントの読み込み（HGゴシックM）
    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      final fontData = await rootBundle.load('assets/fonts/HGGothicM.ttf');
      fontRegular = pw.Font.ttf(fontData);
      fontBold = fontRegular;
    } catch (e) {
      fontRegular = await PdfGoogleFonts.notoSansJPRegular();
      fontBold = await PdfGoogleFonts.notoSansJPBold();
    }

    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    // 2. 余白設定（左2cm, 下2cm, 右1.5cm, 上1.5cm）
    final margin = pw.EdgeInsets.fromLTRB(
      2.8 * PdfPageFormat.cm, // 左
      2.8 * PdfPageFormat.cm, // 上
      2.6 * PdfPageFormat.cm, // 右
      2.8 * PdfPageFormat.cm, // 下
    );

    // 【修正点】余計なスペースを全て消し去った「純粋な文字列」を作ります
    final cleanTitle = reportTitle.replaceAll(' ', '').replaceAll('　', '');

    return pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: margin,
      build: (context) => pw.Container(
        // 外側の枠線（太線）
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 1.5, color: PdfColors.black),
        ),
        padding: const pw.EdgeInsets.all(3.0),
        child: pw.Container(
          // 内側の枠線（細線）
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5, color: PdfColors.black),
          ),
          width: double.infinity,
          height: double.infinity,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Spacer(flex: 11),

              // --- 1. 工事名 ---
              pw.Text(
                projectName,
                style: const pw.TextStyle(fontSize: 18),
                textAlign: pw.TextAlign.center,
              ),

              pw.Spacer(flex: 11),

              // --- 2. 報告書タイトル ---
              // 【完璧な中央揃えロジック】左側にletterSpacingと同じ値のPaddingを入れて相殺する！
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12.0),
                child: pw.Text(
                  cleanTitle, // スペースが一切入っていない純粋な文字列を渡す
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 12.0, // ★ここで「半角1文字分」の隙間を均等に作る
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.Spacer(flex: 27),

              // --- 3. 会社名 ---
              pw.Text(
                companyName,
                style: const pw.TextStyle(fontSize: 16),
                textAlign: pw.TextAlign.center,
              ),

              pw.Spacer(flex: 14),
            ],
          ),
        ),
      ),
    );
  }
}
