import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert'; // utf8.decode

import 'shift_jis_decoder_stub.dart' if (dart.library.js_interop) 'shift_jis_decoder_web.dart';

import 'project_create_screen.dart';

// provider リセット用
import '../../gantt/presentation/gantt_screen.dart' show inspectionFilterProvider;
import '../../shipping/application/shipping_table_notifier.dart' show shippingTableProvider;

// gantt_screen.dart にあるエンコード関数をこのファイルでも利用できるようインポートするか、
// 共通の utils などに切り出す必要があります。今回は元のファイルと同じ場所にある前提でインポートを試みますが、
// _decodeCsvBytes はプライベートなので、ここでは専用のデコード関数を用意するか、
// import '../gantt/presentation/gantt_screen.dart' のようにします。
// ただし dart:js_interop などの依存があるため、元のファイルのトップに置いてあるものを
// gantt_utils.dart などに移動させるのがベストですが、要件として csv import の移行が指示されているため、
// ここに再定義（もしくは public 化したものを呼び出し）します。

/// CSV バイト列を正しい文字列にデコードする。
String _decodeCsvBytes(Uint8List bytes) {
  try {
    final s = utf8.decode(bytes);
    return s.startsWith('\uFEFF') ? s.substring(1) : s;
  } catch (_) {}
  try {
    return decodeShiftJis(bytes);
  } catch (_) {
    return String.fromCharCodes(bytes);
  }
}

class ProjectSettingsScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectSettingsScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProjectSettingsScreen> createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends ConsumerState<ProjectSettingsScreen> {
  bool _isImporting = false;

  Future<void> _importCsvAndSave(BuildContext context) async {
    final projectId = widget.projectId;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // ── 1. ファイル選択 ──────────────────────────────────────────────
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('ファイルの読み込みに失敗しました')),
      );
      return;
    }

    // ── 2. 文字デコード ────────────────────────────────
    final csvString = _decodeCsvBytes(bytes);

    // ── 3. CSVパース ────────────────────────────────
    final List<List<dynamic>> rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(csvString);

    if (rows.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('CSVにデータがありません')),
      );
      return;
    }

    final headers = rows.first.map((h) => h.toString().trim()).toList();
    final idxCode = headers.indexOf('製品符号');
    final idxArea = headers.indexOf('工区');
    final idxSetsu = headers.indexOf('節');
    final idxFloor = headers.indexOf('階');
    final idxKind = headers.indexOf('種別');
    final idxSection = headers.indexOf('断面寸法');
    final idxDir = headers.indexOf('方向');
    var idxL = headers.indexOf('長さ');
    if (idxL == -1) idxL = headers.indexOf('L'); // 長さがない場合はLを試す
    final idxD1 = headers.indexOf('D1');
    final idxD2 = headers.indexOf('D2');

    if (idxCode == -1) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('CSVに「製品符号」列が見つかりません')),
      );
      return;
    }

    final dataRows = rows.skip(1).where((r) {
      if (r.isEmpty) return false;
      final code = idxCode < r.length ? r[idxCode].toString().trim() : '';
      return code.isNotEmpty;
    }).toList();

    if (dataRows.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('有効なデータ行がありません')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    // ── 4. WriteBatch で一括保存 (Upsert) ──────────────────────
    try {
      final col = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('products');

      const batchSize = 500;
      int saved = 0;

      for (int start = 0; start < dataRows.length; start += batchSize) {
        final chunk = dataRows.sublist(
          start,
          (start + batchSize).clamp(0, dataRows.length),
        );
        final batch = FirebaseFirestore.instance.batch();
        for (final row in chunk) {
          String cell(int idx) =>
              idx >= 0 && idx < row.length ? row[idx].toString().trim() : '';

          final code = cell(idxCode);
          final area = cell(idxArea);
          final setsu = cell(idxSetsu);
          final floor = cell(idxFloor);
          final kind = cell(idxKind);
          final section = cell(idxSection);
          final dir = cell(idxDir);
          final lStr = cell(idxL);
          final d1Str = cell(idxD1);
          final d2Str = cell(idxD2);

          // 断面寸法がない場合、D1とD2があれば組み立てる（以前の互換）
          final finalSection = section.isNotEmpty 
              ? section 
              : (d1Str.isNotEmpty && d2Str.isNotEmpty ? '${d1Str}x$d2Str' : '');

          // ドキュメントIDを projectId_code にして一意に保つ
          final docId = '${projectId}_$code';
          final docRef = col.doc(docId);
          
          batch.set(docRef, {
            'productCode': code,
            'area': area,
            'storyOrSet': setsu, // PMSの旧構造では「storyOrSet」が節やグリッドとして使われている可能性が高い
            'floor': floor,
            'memberType': kind, // PMSの旧構造では「memberType」が種別として使われている
            'section': finalSection,
            'direction': dir,
            'lengthMm': int.tryParse(lStr) ?? 0,
            'd1': int.tryParse(d1Str) ?? 0,
            'd2': int.tryParse(d2Str) ?? 0,
            'status': '未',
            'projectId': projectId,
            'overallStatus': 'not_started',
            // createdAt は初回のみ設定されるための工夫が必要だが、
            // merge: true の場合、フィールドが既に存在すれば影響しないため、
            // 一旦簡略化のためここからの `createdAt` の上書きは避けるか、常に新しいタイムスタンプにする。
            // 今回は作成日時フィールドがない場合のみ追加するのがベストだが、バッチ処理では難しい。
            // そこで、今回は createdAt をそのまま保持または新規のみ追加とするため削除し、別途処理する。
            // ただし、単純なSetOptions(merge: true)の場合は指定したキーだけが更新される。
          }, SetOptions(merge: true)); // 上書きモード
        }
        await batch.commit();
        saved += chunk.length;
      }

      if (!mounted) return;
      
      // キャッシュリセット
      ref.read(shippingTableProvider.notifier).clear();
      ref.read(inspectionFilterProvider.notifier).clearAll();
      
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('CSVを読み込みました ($saved件を更新/追加しました)')),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('物件設定'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '製品データのインポート',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('CSVファイルから製品データをインポートします。既存の製品データは製品符号をキーに上書き更新（Upsert）されます。'),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CSVフォーマット: UTF-8 または Shift-JIS'),
                      const Text('必須項目: 製品符号'),
                      const Text('利用項目: 工区, 節, 階, 種別, 断面寸法, 方向, 長さ(L), D1, D2'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isImporting ? null : () => _importCsvAndSave(context),
                          icon: _isImporting 
                              ? const SizedBox(
                                  width: 20, 
                                  height: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(_isImporting ? 'インポート中...' : 'CSVを選択してインポート'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '物件の管理',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('新しい物件（プロジェクト）を作成します。'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProjectCreateScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('新規物件の作成'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
