import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../features/tape_inspection/models/tape_inspection_model.dart';

class ExcelExportService {
  /// 鋼製巻尺検査報告書のExcelをエクスポートする
  Future<void> exportTapeInspectionReport({
    required TapeInspection inspection,
    required String projectName,
    required String companyName,
    String reportTitle = '鋼製巻尺 検査報告書',
    String weather = '晴れ',
    String temperature = '20°C',
    String humidity = '60%',
  }) async {
    var excel = Excel.createExcel();
    // デフォルトのシート名を変更
    var sheetName = '報告書';
    excel.rename('Sheet1', sheetName);
    var sheet = excel[sheetName];

    _buildCoverSheet(
      sheet: sheet,
      projectName: projectName,
      reportTitle: reportTitle,
      companyName: companyName,
      inspectionDate: inspection.inspectionDate,
      inspectorName: inspection.inspectorName,
    );

    _buildSummaryData(
      sheet: sheet,
      inspection: inspection,
      weather: weather,
      temperature: temperature,
      humidity: humidity,
      startRow: 25, // 表紙の下から開始
    );

    // ファイルに保存して共有
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final filePath = '${directory.path}/tape_inspection_$dateStr.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // share_plusでファイルを共有・保存ダイアログを開く
      await Share.shareXFiles([
        XFile(filePath),
      ], text: '$projectName $reportTitle');
    }
  }

  /// 共通表紙レイアウトの構築
  void _buildCoverSheet({
    required Sheet sheet,
    required String projectName,
    required String reportTitle,
    required String companyName,
    DateTime? inspectionDate,
    String? inspectorName,
  }) {
    // 列幅の調整
    sheet.setColumnWidth(0, 5); // 余白用
    for (int i = 1; i <= 8; i++) {
      sheet.setColumnWidth(i, 8.5); // 中央部
    }
    sheet.setColumnWidth(9, 5); // 余白用

    // 外枠の二重線を描画（Row 2 〜 30, Col 1 〜 8）
    const borderTopRow = 2;
    const borderBottomRow = 30;
    const borderLeftCol = 1;
    const borderRightCol = 8;

    for (int r = borderTopRow; r <= borderBottomRow; r++) {
      for (int c = borderLeftCol; c <= borderRightCol; c++) {
        Border? top = r == borderTopRow
            ? Border(borderStyle: BorderStyle.Double)
            : null;
        Border? bottom = r == borderBottomRow
            ? Border(borderStyle: BorderStyle.Double)
            : null;
        Border? left = c == borderLeftCol
            ? Border(borderStyle: BorderStyle.Double)
            : null;
        Border? right = c == borderRightCol
            ? Border(borderStyle: BorderStyle.Double)
            : null;
        if (top != null || bottom != null || left != null || right != null) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
              .cellStyle = CellStyle(
            topBorder: top,
            bottomBorder: bottom,
            leftBorder: left,
            rightBorder: right,
          );
        }
      }
    }

    // 工事名
    const projectNameRow = 6;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: projectNameRow),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: projectNameRow),
    );
    var projectCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: projectNameRow),
    );
    projectCell.value = TextCellValue(projectName);
    projectCell.cellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bold: true,
      fontSize: 16,
    );

    // 報告書タイトル（枠なし、字間空け）
    const titleRowStart = 11;
    const titleRowEnd = 13;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: titleRowStart),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: titleRowEnd),
    );
    var titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: titleRowStart),
    );
    final spacedTitle = reportTitle.replaceAll(' ', '').split('').join('　');
    titleCell.value = TextCellValue(spacedTitle);
    titleCell.cellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bold: true,
      fontSize: 22,
    );

    // 会社名
    const companyRow = 25;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: companyRow),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: companyRow),
    );
    var companyCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: companyRow),
    );
    companyCell.value = TextCellValue(companyName);
    companyCell.cellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bold: true,
      fontSize: 14,
    );
  }

  /// 測定結果データの構築
  void _buildSummaryData({
    required Sheet sheet,
    required TapeInspection inspection,
    required String weather,
    required String temperature,
    required String humidity,
    required int startRow,
  }) {
    var currentRow = startRow;

    // タイトル
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow),
    );
    var summaryTitle = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
    );
    summaryTitle.value = TextCellValue('測定結果記録表');
    summaryTitle.cellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      bold: true,
      fontSize: 14,
    );
    currentRow += 2;

    // 基本情報テーブル
    final infoRows = [
      [
        '検査日',
        DateFormat('yyyy年MM月dd日').format(inspection.inspectionDate),
        '天候',
        weather,
      ],
      ['検査員', inspection.inspectorName, '気温', temperature],
      ['使用テープ張力（工場）', '50N', '湿度', humidity],
      ['使用テープ張力（現場）', '50N', '規定張力', inspection.tension],
    ];

    final borderStyle = CellStyle(
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyle = CellStyle(
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
      bold: true,
    );

    for (var rowData in infoRows) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
      );
      var lCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
      );
      lCell.value = TextCellValue(rowData[0]);
      lCell.cellStyle = headerStyle;
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: 2,
                  rowIndex: currentRow,
                ),
              )
              .cellStyle =
          headerStyle;

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
      );
      var vCell1 = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
      );
      vCell1.value = TextCellValue(rowData[1]);
      vCell1.cellStyle = borderStyle;
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: 4,
                  rowIndex: currentRow,
                ),
              )
              .cellStyle =
          borderStyle;

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      var lCell2 = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
      );
      lCell2.value = TextCellValue(rowData[2]);
      lCell2.cellStyle = headerStyle;
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: 6,
                  rowIndex: currentRow,
                ),
              )
              .cellStyle =
          headerStyle;

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow),
      );
      var vCell2 = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow),
      );
      vCell2.value = TextCellValue(rowData[3]);
      vCell2.cellStyle = borderStyle;
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: 8,
                  rowIndex: currentRow,
                ),
              )
              .cellStyle =
          borderStyle;

      currentRow++;
    }

    currentRow += 2;

    // 計測結果テーブルヘッダー
    final headers = ['測定距離', '工場テープ', '現場テープ', '誤差(mm)', '備考'];
    var colIdx = 1;
    for (var h in headers) {
      int mergeEnd = colIdx;
      if (h == '測定距離' || h == '備考') {
        mergeEnd = colIdx + 1; // 幅調整のため結合
      }
      if (colIdx != mergeEnd) {
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: currentRow),
          CellIndex.indexByColumnRow(
            columnIndex: mergeEnd,
            rowIndex: currentRow,
          ),
        );
      }
      var c = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: currentRow),
      );
      c.value = TextCellValue(h);
      c.cellStyle = headerStyle;
      if (colIdx != mergeEnd) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: mergeEnd,
                    rowIndex: currentRow,
                  ),
                )
                .cellStyle =
            headerStyle;
      }
      colIdx = mergeEnd + 1;
    }
    currentRow++;

    // 計測結果データ
    final measurementItems = inspection.items
        .where((i) => i.isMeasurement)
        .toList();
    for (var item in measurementItems) {
      colIdx = 1;

      // 測定距離
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: currentRow),
        CellIndex.indexByColumnRow(
          columnIndex: colIdx + 1,
          rowIndex: currentRow,
        ),
      );
      var c1 = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: currentRow),
      );
      c1.value = TextCellValue(item.name);
      c1.cellStyle = borderStyle;
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIdx + 1,
                  rowIndex: currentRow,
                ),
              )
              .cellStyle =
          borderStyle;
      colIdx += 2;

      // 工場テープ
      var c2 = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: currentRow),
      );
      c2.value = TextCellValue('基準');
      c2.cellStyle = borderStyle;
      colIdx++;

      // 現場テープ
      var c3 = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: currentRow),
      );
      c3.value = TextCellValue(
        item.errorValue.isNotEmpty ? item.errorValue : '-',
      );
      c3.cellStyle = borderStyle;
      colIdx++;

      // 誤差
      var c4 = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: currentRow),
      );
      c4.value = TextCellValue(
        item.errorValue.isNotEmpty ? '${item.errorValue} mm' : '-',
      );
      c4.cellStyle = borderStyle;
      colIdx++;

      // 備考
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: currentRow),
        CellIndex.indexByColumnRow(
          columnIndex: colIdx + 1,
          rowIndex: currentRow,
        ),
      );
      var c5 = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: currentRow),
      );
      c5.value = TextCellValue(_getJudgement(item.errorValue));
      c5.cellStyle = borderStyle;
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIdx + 1,
                  rowIndex: currentRow,
                ),
              )
              .cellStyle =
          borderStyle;

      currentRow++;
    }
  }

  String _getJudgement(String errorValue) {
    if (errorValue.isEmpty) return '-';
    final val = double.tryParse(errorValue.replaceAll('+', ''));
    if (val == null) return '-';
    return val.abs() <= 3.0 ? '合格' : '不合格';
  }
}
