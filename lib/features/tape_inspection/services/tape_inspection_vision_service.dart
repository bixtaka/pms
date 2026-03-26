import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TapeInspectionVisionService {
  // AI Prompt Definition
  static const String PROMPT = '''
あなたは建設現場の品質管理を行う精密画像解析プログラムです。
画像には上下に配置された2つの鋼製巻尺（メジャー）が写っています。
・上段：基準となる工場テープ
・下段：検査対象の現場テープ

感覚的な推測を排除し、以下の【ピクセル計算プロセス】に沿って数学的にズレ（mm）を算出して結果を出力してください。

【ピクセル計算プロセス】
1. 【PPM (Pixels Per Millimeter) の算出】
   上段のメジャーの目盛りを観察し、「1mmの目盛りと隣の目盛りの間の距離」が画像上で概算で何ピクセルに相当するかを推計してください。（例：1mm = 約40ピクセル）
2. 【基準X座標の特定】
   上段のメジャーの中心にある赤い基準線（例：5mなど）の、画像内での横方向の位置（X座標）を仮決めしてください。
3. 【比較X座標の特定】
   下段のメジャーの同じ数値の線の横方向の位置（X座標）を特定してください。
4. 【ピクセル差分の計算】
   下段のX座標 - 上段のX座標 を計算し、何ピクセルずれているかを出します。
   - 下段が左にズレている場合：プラス（+）
   - 下段が右にズレている場合：マイナス（-）
5. 【ミリ単位への変換】
   手順4のズレ（ピクセル数）を、手順1のPPM（1mmあたりのピクセル数）で割り算してください。
   計算式： ズレ(mm) = ズレ(ピクセル) ÷ PPM
6. 【丸め処理】
   算出された数値を「小数第2位（0.01mm単位）」に四捨五入して確定させます。

【出力形式】
まず上記の1〜6の計算プロセスをテキストで詳細に出力し、最後に必ず以下のXMLタグで囲んで結論の数値を出力してください。数値は必ず「小数第2位まで」記述してください（例：0の場合は 0.00）。
<result>+0.50</result>
<result>-1.25</result>
<result>0.00</result>
''';

  /// Real AI Service to analyze gap from an image using Gemini API
  Future<String> analyzeGap(Uint8List imageBytes) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
        throw Exception('GEMINI_API_KEY is not set in .env file');
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(temperature: 0.0),
      );

      // Create data part from bytes
      final dataPart = DataPart(
        'image/jpeg',
        imageBytes,
      ); // Assumption: JPEG or PNG works

      // Send request
      final content = [
        Content.multi([TextPart(PROMPT), dataPart]),
      ];

      final response = await model.generateContent(content);
      final text = response.text;

      if (text != null) {
        // Extract value using regex from <result> tag
        final match = RegExp(
          r'<result>([+-]?\d+\.\d{2})</result>',
        ).firstMatch(text);

        if (match != null && match.groupCount >= 1) {
          return match.group(1)!;
        } else {
          debugPrint('Failed to extract result from AI response:\n$text');
          throw Exception('解析エラー: AIの回答から数値を抽出できませんでした。');
        }
      } else {
        throw Exception('No text returned from Gemini API');
      }
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      rethrow;
    }
  }
}
