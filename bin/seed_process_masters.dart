// dart run bin/seed_process_masters.dart
//
// 前提:
// - GOOGLE_APPLICATION_CREDENTIALS 環境変数に Service Account JSON を設定しておく
//   例: export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service_account.json
// - pubspec.yaml に googleapis_auth / googleapis を追加済みであること

import 'dart:convert';
import 'dart:io';
import 'package:googleapis/firestore/v1.dart' as fs;
import 'package:googleapis_auth/auth_io.dart';

/// 1ドキュメント分の情報（id と Document 本体）
class MasterDoc {
  final String id;
  final fs.Document doc;
  const MasterDoc(this.id, this.doc);
}

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

    // マスタ一覧を生成
    final masters = _buildMasters();

    // 逐次で投入（重複IDがあれば上書き）
    for (final m in masters) {
      await api.projects.databases.documents.createDocument(
        m.doc,
        dbParent,
        'processMasters', // collectionId
        documentId: m.id,
      );
    }

    stdout.writeln('✅ processMasters seeding completed. count=${masters.length}');
    client.close();
  } catch (e, st) {
    stderr.writeln('❌ Seeding failed: $e');
    stderr.writeln(st);
    exitCode = 1;
  }
}

/// 工程マスタのリストを作成
List<MasterDoc> _buildMasters() {
  final List<MasterDoc> result = [];

  fs.Value strVal(String v) => fs.Value(stringValue: v);
  fs.Value boolVal(bool v) => fs.Value(booleanValue: v);
  fs.Value intVal(int v) => fs.Value(integerValue: '$v');

  void addStage(String memberType, String stage, List<String> names,
      {bool isInspection = false}) {
    for (var i = 0; i < names.length; i++) {
      final name = names[i];
      final id = '${memberType.toLowerCase()}_${stage}_$i'
          .replaceAll(' ', '_');
      result.add(
        MasterDoc(
          id,
          fs.Document(fields: {
            'id': strVal(id),
            'name': strVal(name),
            'memberType': strVal(memberType),
            'stage': strVal(stage),
            'orderInStage': intVal(i + 1),
            'isInspection': boolVal(isInspection),
          }),
        ),
      );
    }
  }

  // 柱 (COLUMN)
  addStage('COLUMN', '一次加工',
      ['切断', '孔あけ', '開先加工', 'ショットブラスト']);
  addStage('COLUMN', 'コア部', ['罫書', '組立', 'コア溶接', 'コアUT'],
      isInspection: false);
  addStage(
      'COLUMN',
      '仕口部',
      ['罫書', '組立', '組立検査', '溶接', 'UT'],
      isInspection: false);
  addStage('COLUMN', '大組部', ['罫書', '組立', '溶接', 'UT', '寸法検査'],
      isInspection: false);
  addStage(
      'COLUMN', '二次部材', ['罫書', '組立', '組立検査', '溶接'],
      isInspection: false);
  addStage('COLUMN', '製品検査', ['製品検査'], isInspection: true);
  addStage('COLUMN', '塗装', ['塗装', '検査'], isInspection: true);
  addStage('COLUMN', '積込', ['積込']);
  addStage('COLUMN', '出荷', ['出荷']);

  // 大梁・小梁・間柱 (GIRDER/BEAM/INTERMEDIATE)
  for (final type in ['GIRDER', 'BEAM', 'INTERMEDIATE']) {
    addStage(type, '一次加工',
        ['切断', '孔あけ', '開先加工', 'ショットブラスト']);
    addStage(type, 'ケガキ', ['ケガキ']);
    addStage(type, '組立', ['組立']);
    addStage(type, '組立検査', ['組立検査'], isInspection: true);
    addStage(type, '溶接', ['溶接']);
    addStage(type, '寸法検査', ['寸法検査'], isInspection: true);
    addStage(type, 'UT', ['UT'], isInspection: true);
    addStage(type, '製品検査', ['製品検査'], isInspection: true);
    addStage(type, '塗装', ['塗装', '検査'], isInspection: true);
    addStage(type, '積込', ['積込']);
    addStage(type, '出荷', ['出荷']);
  }

  // 胴縁・母屋・他 (COMMON)
  addStage('COMMON', '一次加工',
      ['切断', '孔あけ', '開先加工', 'ショットブラスト']);
  addStage('COMMON', 'ケガキ', ['ケガキ']);
  addStage('COMMON', '組立', ['組立']);
  addStage('COMMON', '溶接', ['溶接']);
  addStage('COMMON', '塗装', ['塗装', '検査'], isInspection: true);
  addStage('COMMON', '積込', ['積込']);
  addStage('COMMON', '出荷', ['出荷']);

  return result;
}
