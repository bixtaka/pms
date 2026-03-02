import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/pdf/report_cover_builder.dart';
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

    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    // ① 表紙
    doc.addPage(
      await ReportCoverBuilder.buildCommonCover(
        projectName: projectName,
        reportTitle: '鋼製巻尺報告書',
        companyName: companyName,
      ),
    );

    // ② 測定結果記録表
    doc.addPage(
      _buildSummaryPage(
        theme: theme,
        inspection: inspection,
        projectName: projectName,
        companyName: companyName,
        weather: weather,
        temperature: temperature,
        humidity: humidity,
      ),
    );

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

  // ===== ② 測定結果記録表 =====
  pw.Page _buildSummaryPage({
    required pw.ThemeData theme,
    required TapeInspection inspection,
    required String projectName,
    required String companyName,
    required String weather,
    required String temperature,
    required String humidity,
  }) {
    final measurementItems = inspection.items.where((i) {
      if (!i.isMeasurement) return false;
      final clean = i.name.replaceAll(RegExp(r'[^0-9.]'), '');
      final length = double.tryParse(clean) ?? 0;
      return length <= 30;
    }).toList();

    // 合否判定
    bool isAllPassed = true;
    for (final item in measurementItems) {
      if (item.errorValue.isNotEmpty &&
          !_isWithinTolerance(item.errorValue, item.name)) {
        isAllPassed = false;
      }
    }
    final finalJudgement = isAllPassed ? '合　格' : '不合格';

    return pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.fromLTRB(
        2.8 * PdfPageFormat.cm,
        2.8 * PdfPageFormat.cm,
        1.8 * PdfPageFormat.cm,
        0.8 * PdfPageFormat.cm,
      ),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // タイトル
          pw.Center(
            child: pw.Text(
              '鋼　製　巻　尺　検　査　報　告　書',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),

          // 基本情報テーブル（2列）
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(3),
            },
            children: [
              _row2Cols(
                '検査日',
                DateFormat('yyyy年MM月dd日').format(inspection.inspectionDate),
              ),
              _row2Cols(
                '場所',
                [companyName, projectName].where((e) => e.isNotEmpty).join('　'),
              ),
              _row2Cols('天候', weather),
              _row2Cols('気温', temperature),
              _row2Cols('湿度', humidity),
              _row2Cols('張力（現場）', inspection.tension),
              _row2Cols('張力（工場）', '50N'),
            ],
          ),
          pw.SizedBox(height: 30),

          // 計測結果テーブル（4列）
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  _cellC('現場テープ'),
                  _cellC('工場テープ'),
                  _cellC('許容誤差'),
                  _cellC('備考'),
                ],
              ),
              ...measurementItems.map((item) {
                final label = item.name.toUpperCase().endsWith('M')
                    ? item.name
                    : '${item.name}M';
                final allowedStr = '±${_allowedError(item.name)}';
                final judgement = item.errorValue.isNotEmpty
                    ? (_isWithinTolerance(item.errorValue, item.name)
                          ? ''
                          : '不合格')
                    : '';
                return pw.TableRow(
                  children: [
                    _cellC(label),
                    _cellC(
                      item.errorValue.isNotEmpty
                          ? (() {
                              final d = double.tryParse(
                                item.errorValue.replaceAll('+', ''),
                              );
                              if (d == null) return item.errorValue;
                              final s = d.toStringAsFixed(1);
                              return d > 0 ? '+$s' : (d == 0 ? '±0.0' : s);
                            })()
                          : '',
                    ),
                    _cellC(allowedStr),
                    _cellC(judgement),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 30),

          // JIS B 7512 許容差説明
          pw.Center(
            child: pw.Text(
              '鋼製巻尺の長さの許容差(JIS B 7512抜粋)',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  _cellC('表す量'),
                  _cellC('等級許容差'),
                  _cellC('表す量'),
                  _cellC('等級許容差'),
                ],
              ),
              pw.TableRow(
                children: [
                  _cellC('1m以下'),
                  _cellC('1級±0.3mm'),
                  _cellC('1mを超えるとき'),
                  _cellC('1級:±0.3mmに1m\n(またはその端数)を\n増すごとに0.1mmを\n加えた値'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // 合否判定
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                children: [
                  _cellC('合否判定'),
                  _cellC(finalJudgement, fontSize: 10),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// JIS B 7512 に従った許容差の計算
  String _allowedError(String lengthStr) {
    final clean = lengthStr.replaceAll(RegExp(r'[^0-9.]'), '');
    final length = double.tryParse(clean) ?? 0;
    if (length == 0) return '0';
    final error = 0.3 + ((length.ceil() - 1) * 0.1);
    return error.toStringAsFixed(1);
  }

  /// 許容差内かどうか判定
  bool _isWithinTolerance(String errorValue, String lengthStr) {
    final val = double.tryParse(
      errorValue.replaceAll('+', '').replaceAll('mm', '').trim(),
    );
    if (val == null) return true;
    final clean = lengthStr.replaceAll(RegExp(r'[^0-9.]'), '');
    final length = double.tryParse(clean) ?? 0;
    final allowed = length == 0 ? 0.0 : 0.3 + ((length.ceil() - 1) * 0.1);
    return val.abs() <= allowed;
  }

  /// 2列行 (label + value left-aligned)
  pw.TableRow _row2Cols(String label, String value) {
    return pw.TableRow(
      children: [
        _cellC(label),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  /// センタリングセル
  pw.Widget _cellC(String text, {double fontSize = 10, bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: pw.Center(
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
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
        entries.add(
          _PhotoEntry(
            label: item.name,
            subLabel: '',
            errorValue: '',
            imagePath: path,
          ),
        );
      } else {
        // 計測項目: 全景・近景それぞれをエントリとして追加
        entries.add(
          _PhotoEntry(
            label: '${item.name}地点 誤差確認（全景）',
            subLabel: '上: 工場テープ  下: 現場テープ',
            errorValue: item.errorValue.isNotEmpty
                ? '誤差: ${item.errorValue} mm'
                : '',
            imagePath: item.widePhotoUrl,
          ),
        );
        entries.add(
          _PhotoEntry(
            label: '${item.name}地点 誤差確認（近景）',
            subLabel: '基準線に対するズレ量の計測',
            errorValue: item.errorValue.isNotEmpty
                ? '誤差: ${item.errorValue} mm'
                : '',
            imagePath: item.closeupPhotoUrl,
          ),
        );
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
        entryWidgets.add(
          _buildPhotoRow(theme: theme, entry: entry, imageWidget: imgWidget),
        );
        entryWidgets.add(pw.SizedBox(height: 8));
      }

      pages.add(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  '写真台帳  ($pageIndex/${(entries.length / perPage).ceil()}ページ)',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),
              ...entryWidgets,
            ],
          ),
        ),
      );
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
          pw.SizedBox(width: 280, child: imageWidget),
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
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (entry.subLabel.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      entry.subLabel,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                  if (entry.errorValue.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        border: pw.Border.all(color: PdfColors.blue),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
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
