import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/tape_inspection_model.dart';
import '../services/tape_inspection_pdf_service.dart';

/// 生成されたPDFをプレビューするための全画面ダイアログ
class PdfPreviewScreen extends StatelessWidget {
  final TapeInspection inspection;
  final String projectName;
  final String companyName;

  const PdfPreviewScreen({
    super.key,
    required this.inspection,
    required this.projectName,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDFプレビュー'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PdfPreview(
        build: (_) async {
          final service = TapeInspectionPdfService();
          return service.generateReport(
            inspection: inspection,
            projectName: projectName,
            companyName: companyName,
          );
        },
        allowSharing: true,
        allowPrinting: true,
        canChangePageFormat: false,
        initialPageFormat: PdfPageFormat.a4,
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        previewPageMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        loadingWidget: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('PDF生成中...'),
            ],
          ),
        ),
        onError: (context, error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('PDFの生成に失敗しました:\n$error', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
