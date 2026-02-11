# HANDOVER (次回作業用メモ)

## 【現状のステータス】
*   **撮影項目による初期設定フローの実装完了**:
    *   選択画面から項目を選び、Firestoreへ初期データを登録可能。
    *   データがない場合、リスト画面で「撮影項目を設定する」ボタンを表示 (画面全体を使って見やすく)。
*   **Firestoreデータリセット機能の実装完了**:
    *   リスト画面右上のメニューから全データを完全に削除し、初期状態に戻すことが可能。
    *   リセット後のデータ不整合（ID重複、古いデータの残存）問題を解決済み。
*   **黒板詳細モード（type3）の略図エリア表示**:
    *   カメラ画面で黒板タイプを「詳細」にした場合、略図用の白い描画エリアを表示（現在は枠のみ）。

## 【直近の変更点】
*   **`lib/features/site_photo/screens/site_photo_selection_screen.dart` (新規)**:
    *   マスターデータから撮影項目を選択する画面。
*   **`lib/features/site_photo/services/firestore_service.dart` (修正)**:
    *   `initializeWithSelectedItems`: 選択項目での初期化処理。
    *   `resetAllData`: 全データ削除処理（ループ削除+待機時間追加で確実性を向上）。
    *   `getPhotoItems`: 自動初期化ロジックを削除（空リストを返すように変更）。
*   **`lib/features/site_photo/screens/site_photo_list_screen.dart` (修正)**:
    *   データ空時の表示を画面全体に変更。
    *   AppBarにリセットメニューを追加。
    *   リスト項目の選択状態を視覚的に強化（背景色変更）。
*   **`lib/features/site_photo/screens/site_photo_camera_screen.dart` (修正)**:
    *   `_KokubanDrawingRow` クラスを追加。
    *   `type3` 選択時に略図エリアを表示するロジックを追加。

## 【未解決の課題・エラー】
*   **略図エリアの描画機能**:
    *   現在は白い枠（プレースホルダー）を表示しているのみ。
    *   実際に指やペンで描画し、それを画像として保存・合成する機能は未実装。
*   **PDF作成機能 (Windows)**:
    *   Windows環境では PDF パッケージのファイルパス問題でエラーが出るため、`site_photo_list_screen.dart` 内でコメントアウト中。
    *   iPad（実機）での動作確認が必要。

## 【次回のTodo】
1.  **略図エリアへの描画機能の実装**:
    *   `site_photo_camera_screen.dart` の `_KokubanDrawingRow` を拡張し、`GestureDetector` や `CustomPaint` (または `flutter_painter` パッケージ) を導入して描画可能にする。
2.  **実機（iPad）での動作確認**:
    *   PDF作成機能の有効化とテスト。
    *   カメラ撮影・アップロード処理の確認。
3.  **黒板レイアウトの微調整**:
    *   実機での見え方、文字サイズ、略図エリアの大きさの調整。
