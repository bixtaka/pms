import '../domain/process_group.dart';

/// 既存の processMasters コレクションを SPEC の process_groups に読み替えるアダプタ
class ProcessGroupsRepository {
  static const _specGroups = <String>[
    '一次加工',
    'コア部',
    '仕口部',
    '大組部',
    '二次部材',
    '製品検査',
    '製品塗装',
    '積込',
    '出荷',
    'その他',
  ];

  /// 全件読み込み（SPEC の ProcessGroup に変換）
  Future<List<ProcessGroup>> fetchAll() async {
    return [
      for (var i = 0; i < _specGroups.length; i++)
        ProcessGroup(
          id: _specGroups[i],
          key: _specGroups[i],
          label: _specGroups[i],
          sortOrder: i,
        ),
    ];
  }
}
