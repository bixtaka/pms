
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/tape_inspection_model.dart';
import '../services/tape_inspection_vision_service.dart';

class TapeInspectionScreen extends ConsumerStatefulWidget {
  const TapeInspectionScreen({super.key});

  @override
  ConsumerState<TapeInspectionScreen> createState() => _TapeInspectionScreenState();
}

class _TapeInspectionScreenState extends ConsumerState<TapeInspectionScreen> {

  int _selectedCheckpointIndex = 0;
  late TapeInspection _inspection;
  final _visionService = TapeInspectionVisionService();
  final _errorController = TextEditingController();
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    // モックデータで初期化
    _inspection = TapeInspection(
      id: 'mock-id',
      projectId: 'mock-project-id',
      inspectionDate: DateTime.now(),
      inspectorName: 'Mock Inspector',
      tension: '50N',
      checkpoints: List.generate(7, (index) {
        return TapeCheckpoint(
          distance: '${index * 5}m',
        );
      }),
    );
    _updateErrorController();
  }

  @override
  void dispose() {
    _errorController.dispose();
    super.dispose();
  }

  void _updateErrorController() {
    _errorController.text = _inspection.checkpoints[_selectedCheckpointIndex].errorValue;
  }


  Future<void> _pickImage(bool isCloseup) async {
    if (_isAnalyzing) return; // 解析中は連打防止のためリターン

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

      final checkpoint = _inspection.checkpoints[_selectedCheckpointIndex];
      
      setState(() {
        var newCheckpoints = List<TapeCheckpoint>.from(_inspection.checkpoints);
        newCheckpoints[_selectedCheckpointIndex] = isCloseup
            ? checkpoint.copyWith(
                closeupPhotoUrl: photo.path,
                isCloseupPhotoTaken: true,
              )
            : checkpoint.copyWith(
                widePhotoUrl: photo.path,
                isWidePhotoTaken: true,
              );
        _inspection = _inspection.copyWith(checkpoints: newCheckpoints);
      });

      // 近景の場合、AI解析を実行
      if (isCloseup) {
        // WebではFile(path)が使えないため、XFileから直接バイトデータを読み取って渡す
        final bytes = await photo.readAsBytes();
        await _analyzeImage(bytes);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('カメラの起動に失敗しました: $e')),
      );
    }
  }

  DateTime? _lastApiCallTime;

  Future<void> _analyzeImage(Uint8List imageBytes) async {
    // 429エラーを防ぐためのクールダウン設定（前回から60秒以内はブロック）
    if (_lastApiCallTime != null) {
      final difference = DateTime.now().difference(_lastApiCallTime!);
      if (difference.inSeconds < 60) {
        final waitTime = 60 - difference.inSeconds;
        debugPrint('Cooldown active: wait $waitTime seconds');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('連続呼び出し防止：あと $waitTime 秒お待ちください')),
        );
        return;
      }
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      debugPrint('[API CALL] Sending request to Gemini API...');
      _lastApiCallTime = DateTime.now(); // 呼び出し時刻を記録
      
      final result = await _visionService.analyzeGap(imageBytes);
      
      debugPrint('[API SUCCESS] Received result: $result');
      
      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
        // 誤差値を更新
        _errorController.text = result;
        
        // モデルも更新
        var newCheckpoints = List<TapeCheckpoint>.from(_inspection.checkpoints);
        newCheckpoints[_selectedCheckpointIndex] = newCheckpoints[_selectedCheckpointIndex].copyWith(
          errorValue: result,
        );
        _inspection = _inspection.copyWith(checkpoints: newCheckpoints);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI解析完了: 誤差 $result mm')),
      );
    } catch (e) {
      debugPrint('[API ERROR] Failed to analyze image: $e');
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI解析エラー: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('テープ合わせ（鋼製巻尺検査）'),
      ),
      body: Row(
        children: [
          // 左ペイン: 測定点リスト
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: _inspection.checkpoints.length,
              itemBuilder: (context, index) {
                final checkpoint = _inspection.checkpoints[index];
                final isSelected = index == _selectedCheckpointIndex;
                return ListTile(
                  title: Text(checkpoint.distance),
                  selected: isSelected,
                  selectedTileColor: Colors.blue.withOpacity(0.1),
                  leading: Icon(
                    Icons.check_circle,
                    color: (checkpoint.isWidePhotoTaken && checkpoint.isCloseupPhotoTaken)
                        ? Colors.green
                        : Colors.grey,
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
          const VerticalDivider(width: 1),
          // 右ペイン: 詳細・撮影
          Expanded(
            flex: 3,
            child: _buildDetailPane(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPane() {
    final checkpoint = _inspection.checkpoints[_selectedCheckpointIndex];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${checkpoint.distance} 地点',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoCard('全景', checkpoint.widePhotoUrl, () => _pickImage(false)),
                _buildPhotoCard('近景', checkpoint.closeupPhotoUrl, () => _pickImage(true)),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                const Text('誤差 (mm)', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_isAnalyzing) ...[
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Text('AI解析中...', style: TextStyle(color: Colors.blue)),
                ],
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
                  var newCheckpoints = List<TapeCheckpoint>.from(_inspection.checkpoints);
                  newCheckpoints[_selectedCheckpointIndex] = checkpoint.copyWith(
                    errorValue: value,
                  );
                  _inspection = _inspection.copyWith(checkpoints: newCheckpoints);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String label, String? photoUrl, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _isAnalyzing ? null : onTap, // 解析中はタップ無効化
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isAnalyzing ? Colors.grey[300] : Colors.grey[100], // 解析中は背景色を少し暗く
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
      return Image.network(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else {
      return Image.file(File(path), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
  }
}

