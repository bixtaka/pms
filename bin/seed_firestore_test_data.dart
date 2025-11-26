// dart run bin/seed_firestore_test_data.dart
//
// 前提:
// - GOOGLE_APPLICATION_CREDENTIALS 環境変数に Service Account JSON を設定しておく
//   例: export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service_account.json
// - pubspec.yaml に googleapis_auth / googleapis を追加済みであること

import 'dart:convert';
import 'dart:io';
import 'package:googleapis/firestore/v1.dart' as fs;
import 'package:googleapis_auth/auth_io.dart';

Future<void> main() async {
  try {
    final credPath = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
    if (credPath == null || credPath.isEmpty) {
      throw Exception('GOOGLE_APPLICATION_CREDENTIALS が設定されていません');
    }

    // サービスアカウント JSON を読み込み
    final serviceAccountJson = json.decode(
      await File(credPath).readAsString(),
    ) as Map<String, dynamic>;
    final projectId = serviceAccountJson['project_id'] as String?;
    if (projectId == null || projectId.isEmpty) {
      throw Exception('service account に project_id が含まれていません');
    }

    // 認証クライアントを取得
    final scopes = [fs.FirestoreApi.datastoreScope];
    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    final api = fs.FirestoreApi(client);
    final dbParent = 'projects/$projectId/databases/(default)/documents';
    final now = DateTime.now().toUtc().toIso8601String();

    // Firestore 用の Value 変換ヘルパ
    fs.Value strVal(String v) => fs.Value(stringValue: v);
    fs.Value doubleVal(num v) => fs.Value(doubleValue: v.toDouble());
    fs.Value intVal(int v) => fs.Value(integerValue: '$v');
    fs.Value tsVal(String iso) => fs.Value(timestampValue: iso);
    fs.Value nullVal() => fs.Value(nullValue: 'NULL_VALUE');

    // 1件に固定するためドキュメントIDを固定し、既存を削除してから作成
    const projectDocId = 'test_project';
    final projectDocName =
        '$dbParent/projects/$projectDocId'; // projects/{pid}/databases/(default)/documents/projects/test_project
    final product1Name = '$projectDocName/products/p1';
    final product2Name = '$projectDocName/products/p2';

    for (final docName in [product1Name, product2Name, projectDocName]) {
      try {
        await api.projects.databases.documents.delete(docName);
      } catch (_) {
        // 存在しない場合は無視
      }
    }

    // プロジェクトドキュメント作成
    final projectDoc = fs.Document(fields: {
      'name': strVal('テスト工事'),
      'architect': strVal('○○設計事務所'),
      'generalContractor': strVal('△△建設'),
      'tradingCompany': strVal('□□商事'),
      'fabricator': strVal('BIXCEL鉄工'),
      'inspectionAgency': strVal('第三者検査センター'),
      'areaCode': strVal('A工区'),
      'startDate': tsVal(now),
      'endDate': nullVal(),
      'createdAt': tsVal(now),
      'updatedAt': tsVal(now),
    });

    final createdProject = await api.projects.databases.documents.createDocument(
      projectDoc,
      dbParent,
      'projects',
      documentId: projectDocId,
    );
    final projectName = createdProject.name!;

    // products サブコレクションのパス
    // サブコレクション作成時の parent は「ドキュメントパス」まででOK
    final productsParent = projectName; // e.g. projects/{pid}/databases/(default)/documents/projects/{docId}

    // 製品 #1
    final product1 = fs.Document(fields: {
      'productCode': strVal('1C-X1Y1'),
      'memberType': strVal('COLUMN'),
      'storyOrSet': strVal('1C'),
      'grid': strVal('X1Y1'),
      'section': strVal('H-400x200x8x13'),
      'quantity': intVal(1),
      'totalWeight': doubleVal(320.5),
      'overallStatus': strVal('not_started'),
      'overallStartDate': tsVal(now),
      'overallEndDate': nullVal(),
      'remarks': strVal('テスト柱'),
      'projectId': strVal(projectDocId),
      'createdAt': tsVal(now),
      'updatedAt': tsVal(now),
    });
    await api.projects.databases.documents.createDocument(
      product1,
      productsParent,
      'products', // collectionId
      documentId: 'p1',
    );

    // 製品 #2
    final product2 = fs.Document(fields: {
      'productCode': strVal('2G-X1Y1'),
      'memberType': strVal('GIRDER'),
      'storyOrSet': strVal('2G'),
      'grid': strVal('X1Y1'),
      'section': strVal('H-600x200x10x15'),
      'quantity': intVal(1),
      'totalWeight': doubleVal(550.0),
      'overallStatus': strVal('in_progress'),
      'overallStartDate': tsVal(now),
      'overallEndDate': nullVal(),
      'remarks': strVal('テスト大梁'),
      'projectId': strVal(projectDocId),
      'createdAt': tsVal(now),
      'updatedAt': tsVal(now),
    });
    await api.projects.databases.documents.createDocument(
      product2,
      productsParent,
      'products', // collectionId
      documentId: 'p2',
    );

    stdout.writeln('✅ Seed completed. projectId = $projectDocId');
    client.close();
  } catch (e, st) {
    stderr.writeln('❌ Seed failed: $e');
    stderr.writeln(st);
    exitCode = 1;
  }
}
