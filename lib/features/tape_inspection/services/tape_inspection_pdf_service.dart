import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/tape_inspection_model.dart';

class TapeInspectionPdfService {
  /// PDF ドキュメントを生成して Uint8List で返す
  Future<Uint8List> generateReport({
    required TapeInspection inspection,
    required String projectName,
    required String companyName,
    String weather = '晴れ',
    String temperature = '20°C',
    String humidity = '60%',
  }) async {
    final doc = pw.Document();

    // 日本語フォントの読み込み
    final fontRegular = await PdfGoogleFonts.notoSansJPRegular();
    final fontBold = await PdfGoogleFonts.notoSansJPBold();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    // ① 表紙
    doc.addPage(_buildCoverPage(
      theme: theme,
      projectName: projectName,
      companyName: companyName,
      inspection: inspection,
    ));

    // ② 測定結果記録表
    doc.addPage(_buildSummaryPage(
      theme: theme,
      inspection: inspection,
      weather: weather,
      temperature: temperature,
      humidity: humidity,
    ));

    // ③ 写真台帳（複数ページ）
    final photoPages = await _buildPhotoLedgerPages(
      theme: theme,
      inspection: inspection,
    );
    for (final page in photoPages) {
      doc.addPage(page);
    }

    return doc.save();
  }

  // ===== ① 表紙 =====
  pw.Page _buildCoverPage({
    required pw.ThemeData theme,
    required String projectName,
    required String companyName,
    required TapeInspection inspection,
  }) {
    return pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              projectName,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 32),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2, color: PdfColors.black),
              ),
              child: pw.Text(
                '鋼製巻尺 検査報告書',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 48),
            pw.Text(
              '検査日: ${DateFormat('yyyy年MM月dd日').format(inspection.inspectionDate)}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '検査員: ${inspection.inspectorName}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              companyName,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== ② 測定結果記録表 =====
  pw.Page _buildSummaryPage({
    required pw.ThemeData theme,
    required TapeInspection inspection,
    required String weather,
    required String temperature,
    required String humidity,
  }) {
    final measurementItems = inspection.items.where((i) => i.isMeasurement).toList();

    return pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // タイトル
          pw.Center(
            child: pw.Text(
              '測定結果記録表',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),

          // 基本情報テーブル
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              _infoRow('検査日', DateFormat('yyyy年MM月dd日').format(inspection.inspectionDate), '天候', weather),
              _infoRow('検査員', inspection.inspectorName, '気温', temperature),
              _infoRow('使用テープ張力（工場）', '50N', '湿度', humidity),
              _infoRow('使用テープ張力（現場）', '50N', '規定張力', inspection.tension),
            ],
          ),
          pw.SizedBox(height: 20),

          // 計測結果テーブル
          pw.Text(
            '計測結果',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1.2),
            },
            children: [
              // ヘッダー行
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _headerCell('測定距離'),
                  _headerCell('工場テープ'),
                  _headerCell('現場テープ'),
                  _headerCell('誤差 (mm)'),
                  _headerCell('備考'),
                ],
              ),
              // データ行
              ...measurementItems.map((item) => pw.TableRow(
                children: [
                  _dataCell(item.name),
                  _dataCell('基準'),
                  _dataCell(item.errorValue.isNotEmpty ? item.errorValue : '-'),
                  _dataCell(item.errorValue.isNotEmpty ? '${item.errorValue} mm' : '-'),
                  _dataCell(_getJudgement(item.errorValue)),
                ],
              )),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            '※ 許容誤差: ±3mm以内',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  String _getJudgement(String errorValue) {
    if (errorValue.isEmpty) return '-';
    final val = double.tryParse(errorValue.replaceAll('+', ''));
    if (val == null) return '-';
    return val.abs() <= 3.0 ? '合格' : '不合格';
  }

  pw.TableRow _infoRow(String label1, String value1, String label2, String value2) {
    return pw.TableRow(children: [
      _headerCell(label1),
      _dataCell(value1),
      _headerCell(label2),
      _dataCell(value2),
    ]);
  }

  pw.Widget _headerCell(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(6),
        color: PdfColors.grey200,
        child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      );

  pw.Widget _dataCell(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      );

  // ===== ③ 写真台帳ページ群 =====
  Future<List<pw.Page>> _buildPhotoLedgerPages({
    required pw.ThemeData theme,
    required TapeInspection inspection,
  }) async {
    // 写真エントリ構造: (ラベル, 誤差, 画像パス or null)
    final List<_PhotoEntry> entries = [];

    for (final item in inspection.items) {
      if (!item.isMeasurement) {
        // 写真のみ項目: 全景か近景のどちらかを使用
        final path = item.widePhotoUrl ?? item.closeupPhotoUrl;
        entries.add(_PhotoEntry(
          label: item.name,
          subLabel: '',
          errorValue: '',
          imagePath: path,
        ));
      } else {
        // 計測項目: 全景・近景それぞれをエントリとして追加
        entries.add(_PhotoEntry(
          label: '${item.name}地点 誤差確認（全景）',
          subLabel: '上: 工場テープ  下: 現場テープ',
          errorValue: item.errorValue.isNotEmpty ? '誤差: ${item.errorValue} mm' : '',
          imagePath: item.widePhotoUrl,
        ));
        entries.add(_PhotoEntry(
          label: '${item.name}地点 誤差確認（近景）',
          subLabel: '基準線に対するズレ量の計測',
          errorValue: item.errorValue.isNotEmpty ? '誤差: ${item.errorValue} mm' : '',
          imagePath: item.closeupPhotoUrl,
        ));
      }
    }

    // 3エントリで1ページに収める
    const int perPage = 3;
    final pages = <pw.Page>[];
    for (int i = 0; i < entries.length; i += perPage) {
      final chunk = entries.skip(i).take(perPage).toList();
      final pageIndex = (i ~/ perPage) + 1;

      // 各エントリの画像を事前に読み込む
      final entryWidgets = <pw.Widget>[];
      for (final entry in chunk) {
        final imgWidget = await _loadImageWidget(entry.imagePath);
        entryWidgets.add(_buildPhotoRow(
          theme: theme,
          entry: entry,
          imageWidget: imgWidget,
        ));
        entryWidgets.add(pw.SizedBox(height: 8));
      }

      pages.add(pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                '写真台帳  ($pageIndex/${(entries.length / perPage).ceil()}ページ)',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),
            ...entryWidgets,
          ],
        ),
      ));
    }

    return pages;
  }

  pw.Widget _buildPhotoRow({
    required pw.ThemeData theme,
    required _PhotoEntry entry,
    required pw.Widget imageWidget,
  }) {
    return pw.Container(
      height: 230,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 左: 画像エリア
          pw.SizedBox(
            width: 280,
            child: imageWidget,
          ),
          pw.VerticalDivider(color: PdfColors.grey400, width: 1),
          // 右: テキスト情報エリア
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    entry.label,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  if (entry.subLabel.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      entry.subLabel,
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                  if (entry.errorValue.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        border: pw.Border.all(color: PdfColors.blue),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        entry.errorValue,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.Widget> _loadImageWidget(String? path) async {
    if (path == null) {
      return pw.Container(
        color: PdfColors.grey200,
        child: pw.Center(
          child: pw.Text(
            '写真なし',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
        ),
      );
    }

    try {
      Uint8List imageBytes;
      if (path.startsWith('http') || path.startsWith('blob:')) {
        // Web: blob URL はそのまま取得しにくいため placeholder
        return pw.Container(
          color: PdfColors.grey200,
          child: pw.Center(
            child: pw.Text(
              '写真あり',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ),
        );
      } else if (kIsWeb) {
        return pw.Container(
          color: PdfColors.grey200,
          child: pw.Center(
            child: pw.Text(
              '写真あり',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ),
        );
      } else {
        imageBytes = await File(path).readAsBytes();
        final image = pw.MemoryImage(imageBytes);
        return pw.Image(image, fit: pw.BoxFit.cover);
      }
    } catch (e) {
      return pw.Container(
        color: PdfColors.grey200,
        child: pw.Center(
          child: pw.Text(
            'エラー',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.red),
          ),
        ),
      );
    }
  }
}

class _PhotoEntry {
  final String label;
  final String subLabel;
  final String errorValue;
  final String? imagePath;

  _PhotoEntry({
    required this.label,
    required this.subLabel,
    required this.errorValue,
    required this.imagePath,
  });
}
