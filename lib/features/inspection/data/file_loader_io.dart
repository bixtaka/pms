import 'dart:io';
import 'dart:typed_data';

/// iOS/Android 環境用のファイル読み込み実装
/// 
/// dart:io を使用してローカルファイルをバイト配列として読み込む
Future<Uint8List> loadFileBytes(String filePath) async {
  final file = File(filePath);
  return await file.readAsBytes();
}
