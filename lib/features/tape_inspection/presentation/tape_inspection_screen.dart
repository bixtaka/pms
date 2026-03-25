import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/tape_inspection_model.dart';
import 'manual_measurement_overlay.dart';
import 'pdf_preview_screen.dart';
import '../../../../core/excel/excel_export_service.dart';

class TapeInspectionScreen extends ConsumerStatefulWidget {
  const TapeInspectionScreen({super.key});

  @override
  ConsumerState<TapeInspectionScreen> createState() =>
      _TapeInspectionScreenState();
}

class _TapeInspectionScreenState extends ConsumerState<TapeInspectionScreen> {
  int _selectedCheckpointIndex = 0;
  late TapeInspection _inspection;
  final _errorController = TextEditingController();
  final _excelExportService = ExcelExportService();

  @override
  void initState() {
    super.initState();
    // モックデータで初期化（初期項目のセット）
    _inspection = TapeInspection(
      id: 'mock-id',
      projectId: 'mock-project-id',
      inspectionDate: DateTime.now(),
      inspectorName: 'Mock Inspector',
      tension: '50N',
      items: [
        // 写真のみの項目
        TapeInspectionItem(id: 'item_01', name: '集合写真', isMeasurement: false),
        TapeInspectionItem(
          id: 'item_02',
          name: 'テープ合わせ（全景）',
          isMeasurement: false,
        ),
        TapeInspectionItem(id: 'item_03', name: '気温・湿度', isMeasurement: false),
        TapeInspectionItem(
          id: 'item_04',
          name: '張力確認（テープ）（全景）',
          isMeasurement: false,
        ),
        TapeInspectionItem(
          id: 'item_05',
          name: '張力確認（テープ）（現場）（近景）',
          isMeasurement: false,
        ),
        TapeInspectionItem(
          id: 'item_06',
          name: '張力確認（テープ）（工場）（近景）',
          isMeasurement: false,
        ),
        TapeInspectionItem(
          id: 'item_07',
          name: '張力確認（バネ）（全景）',
          isMeasurement: false,
        ),
        TapeInspectionItem(
          id: 'item_08',
          name: '張力確認（バネ）（近景）',
          isMeasurement: false,
        ),
        // 計測ありの項目
        TapeInspectionItem(id: 'item_09', name: '0m', isMeasurement: true),
        TapeInspectionItem(id: 'item_10', name: '5m', isMeasurement: true),
        TapeInspectionItem(id: 'item_11', name: '10m', isMeasurement: true),
        TapeInspectionItem(id: 'item_12', name: '15m', isMeasurement: true),
        TapeInspectionItem(id: 'item_13', name: '20m', isMeasurement: true),
        TapeInspectionItem(id: 'item_14', name: '25m', isMeasurement: true),
      ],
    );
    _updateErrorController();
  }

  @override
  void dispose() {
    _errorController.dispose();
    super.dispose();
  }

  void _updateErrorController() {
    if (_inspection.items.isNotEmpty &&
        _selectedCheckpointIndex < _inspection.items.length) {
      _errorController.text =
          _inspection.items[_selectedCheckpointIndex].errorValue;
    }
  }

  Future<void> _pickImage(bool isCloseup) async {
    try {
      final picker = ImagePicker();
      debugPrint('Picking image...Source: Camera');
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024, // 画像サイズを制限
        maxHeight: 1024,
      );

      if (photo == null) {
        debugPrint('Image selection cancelled');
        return;
      }

      debugPrint('Image picked: ${photo.path}');

      final item = _inspection.items[_selectedCheckpointIndex];

      setState(() {
        var newItems = List<TapeInspectionItem>.from(_inspection.items);
        newItems[_selectedCheckpointIndex] = isCloseup
            ? item.copyWith(
                closeupPhotoUrl: photo.path,
                isCloseupPhotoTaken: true,
              )
            : item.copyWith(widePhotoUrl: photo.path, isWidePhotoTaken: true);
        _inspection = _inspection.copyWith(items: newItems);
      });

      // 手動計測（キャリブレーション）が必要な項目の場合のみ近景撮影後にオーバーレイを表示
      if (isCloseup && item.isMeasurement) {
        if (!mounted) return;
        final result = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (context) =>
                ManualMeasurementOverlay(imagePath: photo.path),
            fullscreenDialog: true,
          ),
        );

        if (result != null && mounted) {
          setState(() {
            _errorController.text = result;
            var newItems = List<TapeInspectionItem>.from(_inspection.items);
            newItems[_selectedCheckpointIndex] =
                newItems[_selectedCheckpointIndex].copyWith(errorValue: result);
            _inspection = _inspection.copyWith(items: newItems);
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('手動計測完了: 誤差 $result mm')));
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('カメラの起動に失敗しました: $e')));
    }
  }

  /// PDF出力プレビュー画面を開く（工事名・会社名の入力ダイアログを経由）
  Future<void> _openPdfPreview(BuildContext context) async {
    final projectNameCtrl = TextEditingController(text: '〇〇工事');
    final companyNameCtrl = TextEditingController(text: '〇〇株式会社');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PDF出力'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: projectNameCtrl,
              decoration: const InputDecoration(labelText: '工事名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: companyNameCtrl,
              decoration: const InputDecoration(labelText: '会社名'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('生成する'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            inspection: _inspection,
            projectName: projectNameCtrl.text,
            companyName: companyNameCtrl.text,
          ),
        ),
      );
    }
  }

  /// Excel出力処理（ダイアログ経由で生成・共有）
  Future<void> _exportExcel(BuildContext context) async {
    final projectNameCtrl = TextEditingController(text: '〇〇工事');
    final companyNameCtrl = TextEditingController(text: '〇〇株式会社');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excel出力'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: projectNameCtrl,
              decoration: const InputDecoration(labelText: '工事名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: companyNameCtrl,
              decoration: const InputDecoration(labelText: '会社名'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('生成する'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _excelExportService.exportTapeInspectionReport(
          inspection: _inspection,
          projectName: projectNameCtrl.text,
          companyName: companyNameCtrl.text,
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Excel出力に失敗しました: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('テープ合わせ（鋼製巻尺検査）'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: OutlinedButton.icon(
              icon: const Text('📄'),
              label: const Text('PDF出力'),
              onPressed: () => _openPdfPreview(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              icon: const Text('📊'),
              label: const Text('Excel出力'),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => _exportExcel(context),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // 左ペイン: 測定点リスト
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _inspection.items.length,
                    itemBuilder: (context, index) {
                      final item = _inspection.items[index];
                      final isSelected = index == _selectedCheckpointIndex;
                      // 写真ありかどうかの判定。計測項目の場合は両方、写真項目の場合は全景のみでOKとするなど柔軟に
                      final isCompleted = item.isMeasurement
                          ? (item.isWidePhotoTaken &&
                                item.isCloseupPhotoTaken &&
                                item.errorValue.isNotEmpty)
                          : (item.isWidePhotoTaken || item.isCloseupPhotoTaken);

                      return ListTile(
                        title: Text(item.name),
                        selected: isSelected,
                        selectedTileColor: Colors.blue.withOpacity(0.1),
                        leading: Icon(
                          Icons.check_circle,
                          color: isCompleted ? Colors.green : Colors.grey,
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditDialog(index, item);
                            } else if (value == 'delete') {
                              _deleteItem(index);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('名前を変更'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                '削除',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCheckpointIndex = index;
                            _updateErrorController();
                          });
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('写真追加'),
                        onPressed: () => _showAddDialog(false),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text('計測追加'),
                        onPressed: () => _showAddDialog(true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // 右ペイン: 詳細・撮影
          Expanded(flex: 3, child: _buildDetailPane()),
        ],
      ),
    );
  }

  Widget _buildDetailPane() {
    if (_inspection.items.isEmpty) {
      return const Center(child: Text('項目がありません'));
    }

    final item = _inspection.items[_selectedCheckpointIndex];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoCard(
                    '全体・全景',
                    item.widePhotoUrl,
                    () => _pickImage(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPhotoCard(
                    '近景',
                    item.closeupPhotoUrl,
                    () => _pickImage(true),
                  ),
                ),
              ],
            ),
            // isMeasurement が true の時だけ誤差UIを表示
            if (item.isMeasurement) ...[
              const SizedBox(height: 30),
              Row(
                children: [
                  const Text(
                    '誤差 (mm)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _errorController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '+0.5',
                  suffixText: 'mm',
                ),
                onChanged: (value) {
                  setState(() {
                    var newItems = List<TapeInspectionItem>.from(
                      _inspection.items,
                    );
                    newItems[_selectedCheckpointIndex] = item.copyWith(
                      errorValue: value,
                    );
                    _inspection = _inspection.copyWith(items: newItems);
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==== リストの操作メソッド ====
  void _showAddDialog(bool isMeasurement) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isMeasurement ? '計測項目を追加' : '写真項目を追加'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: '項目名 (例: 30m, 現場状況)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                setState(() {
                  final newItem = TapeInspectionItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: textController.text,
                    isMeasurement: isMeasurement,
                  );
                  _inspection = _inspection.copyWith(
                    items: [..._inspection.items, newItem],
                  );
                  _selectedCheckpointIndex = _inspection.items.length - 1;
                  _updateErrorController();
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int index, TapeInspectionItem item) {
    final textController = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('名前を変更'),
        content: TextField(controller: textController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                setState(() {
                  var newItems = List<TapeInspectionItem>.from(
                    _inspection.items,
                  );
                  newItems[index] = item.copyWith(name: textController.text);
                  _inspection = _inspection.copyWith(items: newItems);
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    setState(() {
      var newItems = List<TapeInspectionItem>.from(_inspection.items);
      newItems.removeAt(index);
      _inspection = _inspection.copyWith(items: newItems);
      if (_selectedCheckpointIndex >= newItems.length) {
        _selectedCheckpointIndex = newItems.length - 1;
        if (_selectedCheckpointIndex < 0) _selectedCheckpointIndex = 0;
      }
      _updateErrorController();
    });
  }

  Widget _buildPhotoCard(String label, String? photoUrl, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
          ),
          child: photoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(photoUrl),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 40, color: Colors.grey[700]),
                    const SizedBox(height: 8),
                    Text(label, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http') || path.startsWith('blob:')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
  }
}
