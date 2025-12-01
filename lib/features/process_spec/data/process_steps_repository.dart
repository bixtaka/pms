import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/process_step.dart';
import '../../../models/process_master.dart';

/// SPEC の process_steps を提供するアダプタ
/// - processSteps コレクションがあればそれを使用
/// - 無ければ processMasters から stage を SPEC グループ or 「その他」にマッピングした擬似 step を生成する
class ProcessStepsRepository {
  static const _specStages = <String>[
    '一次加工',
    'コア部',
    '仕口部',
    '大組部',
    '二次部材',
    '製品検査',
    '製品塗装',
    '積込',
    '出荷',
  ];

  String _mapStageToGroup(String stage) {
    final trimmed = stage.trim();
    if (trimmed.isEmpty) return 'その他';
    return _specStages.contains(trimmed) ? trimmed : 'その他';
  }

  Future<List<ProcessStep>> fetchAll() async {
    // 既存の processSteps コレクションがあれば優先して使用する
    final stepsSnap =
        await FirebaseFirestore.instance.collection('processSteps').get();
    if (stepsSnap.docs.isNotEmpty) {
      return stepsSnap.docs.map((d) {
        final data = d.data();
        final rawGroupId = (data['groupId'] ??
                data['group_id'] ??
                data['processGroupId'] ??
                data['process_group_id'] ??
                data['stage'] ??
                '')
            .toString()
            .trim();
        final groupId = _mapStageToGroup(rawGroupId);
        final key = (data['key'] ?? data['name'] ?? d.id).toString().trim();
        final label = (data['label'] ?? data['name'] ?? key).toString().trim();
        final sortRaw =
            data['sort_order'] ?? data['sortOrder'] ?? data['order'] ?? 999;
        final sortOrder = sortRaw is int ? sortRaw : (sortRaw as num).toInt();
        return ProcessStep(
          id: d.id,
          groupId: groupId,
          key: key.isNotEmpty ? key : d.id,
          label: label.isNotEmpty ? label : d.id,
          sortOrder: sortOrder,
        );
      }).toList();
    }

    // フォールバック: processMasters から SPEC の process_steps 相当を生成
    final mastersSnap =
        await FirebaseFirestore.instance.collection('processMasters').get();
    final masters =
        mastersSnap.docs.map((d) => ProcessMaster.fromJson(d.data(), d.id));

    return masters
        .map(
          (m) => ProcessStep(
            id: m.id,
            // stage（日本語の工程グループ名）を SPEC グループ or その他 にマッピング
            groupId: _mapStageToGroup(m.stage),
            // キーは一意であれば良いので id を流用
            key: m.id,
            // 子行に表示する工程名（切断／孔あけ／…）
            label: m.name,
            sortOrder: m.orderInStage,
          ),
        )
        .toList();
  }
}
