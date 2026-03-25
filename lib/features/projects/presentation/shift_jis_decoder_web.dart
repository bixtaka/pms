import 'dart:js_interop';
import 'dart:typed_data';

@JS('TextDecoder')
extension type _JsTextDecoder._(JSObject _) implements JSObject {
  external _JsTextDecoder(String encoding);
  external String decode(JSUint8Array buffer);
}

// 呼び出し用の共通メソッド
String decodeShiftJis(List<int> bytes) {
  final decoder = _JsTextDecoder('shift-jis');
  return decoder.decode(Uint8List.fromList(bytes).toJS);
}
