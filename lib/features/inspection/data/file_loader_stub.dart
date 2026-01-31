import 'dart:typed_data';

/// Web 環境用のスタブ実装
/// 
/// Web では dart:io が使用できないため、
/// このスタブがフォールバックとして使用される
Future<Uint8List> loadFileBytes(String filePath) async {
  throw UnsupportedError(
    'loadFileBytes is not supported on Web. '
    'Use file picker with bytes instead.',
  );
}
