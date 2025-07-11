# 生産管理システム (PMS)

Flutter + Firebaseで構築された30人規模の製造業向け生産管理アプリのMVPサンプルです。

## 機能

- **製品リスト**: 柱・大梁・小梁の製品をFirestoreから取得・表示
- **進捗管理**: 各製品の状態（未着手／作業中／完了）をボタンで更新
- **工種別進捗**: 工種ごとの進捗率をリアルタイム表示（例：完成3/10など）
- **ガントチャート**: シンプルなガントチャート表示（ContainerとDate差分で横幅可視化）
- **リアルタイム更新**: StreamBuilderでFirestoreの変更をリアルタイム反映

## 技術スタック

- **フロントエンド**: Flutter
- **バックエンド**: Firebase Firestore
- **状態管理**: StreamBuilder（リアルタイム更新）

## セットアップ手順

### 1. Firebaseプロジェクトの作成

1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. 新しいプロジェクトを作成
3. Firestore Databaseを有効化
4. セキュリティルールを一時的にテストモードに設定

### 2. Firebase設定の更新

`lib/firebase_options.dart`ファイルの設定値を実際のFirebaseプロジェクトの値に更新：

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-actual-api-key',
  appId: 'your-actual-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  authDomain: 'your-actual-project-id.firebaseapp.com',
  storageBucket: 'your-actual-project-id.appspot.com',
);
```

### 3. 依存関係のインストール

```bash
flutter pub get
```

### 4. アプリの実行

```bash
flutter run
```

## Firestoreデータ構造

### products コレクション

```json
{
  "name": "柱-001",
  "type": "柱",
  "status": "not_started", // not_started, in_progress, completed
  "startDate": null, // 作業開始日時
  "endDate": null    // 作業完了日時
}
```

## 使用方法

1. アプリ起動後、右上の「+」ボタンをタップしてサンプルデータを追加
2. 製品リストで各製品の「開始」「完了」ボタンをタップして進捗を更新
3. 工種別進捗とガントチャートがリアルタイムで更新されます

## 今後の拡張予定

- ドラッグ操作でガントチャートバーを移動
- 表示期間の切替（1日、1週間、1か月、3か月、6か月）
- より詳細な進捗管理機能
- ユーザー認証機能
- オフライン対応

## 注意事項

- このMVPは開発・テスト用のサンプルです
- 本格運用前にセキュリティルールの適切な設定が必要です
- Firebase設定値は実際のプロジェクトの値に更新してください
