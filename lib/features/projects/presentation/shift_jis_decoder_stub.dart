// モバイル環境向けの処理（インターフェースを合わせる）
String decodeShiftJis(List<int> bytes) {
  // JS Interopを使用したShift-JISデコードはWeb環境でのみサポートされています。
  // iOS/AndroidでShift-JISデコードが必要な場合は、charset_converter などの別パッケージが必要です。
  throw UnsupportedError('JS Interopを使用したShift-JISデコードはWeb環境でのみサポートされています。');
}
