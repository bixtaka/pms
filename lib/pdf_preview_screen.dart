import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'features/tape_inspection/models/tape_inspection_model.dart';
import 'features/tape_inspection/services/tape_inspection_pdf_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDFレイアウト調整（ホットリロード対応）')),
      body: PdfPreview(
        maxPageWidth: 700,
        build: (format) async {
          // モックデータの作成
          final mockItems = List.generate(
            15,
            (i) => TapeInspectionItem(
              id: 'item_$i',
              name: i < 5 ? '状況写真${i + 1}' : '${(i - 4) * 5}M',
              isMeasurement: i >= 5,
              errorValue: i >= 5 ? '+${(i - 4) * 0.2}' : '',
            ),
          );

          final mockInspection = TapeInspection(
            id: 'mock_doc_id',
            projectId: 'mock_project_id',
            inspectionDate: DateTime.now(),
            inspectorName: 'テスト 太郎',
            tension: '50N',
            items: mockItems,
          );

          final service = TapeInspectionPdfService();
          return await service.generateReport(
            inspection: mockInspection,
            projectName: 'テスト工事',
            companyName: '株式会社テスト',
          );
        },
        useActions: true, // 印刷ボタン等を表示する
      ),
    );
  }
}
