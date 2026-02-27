import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectPhase {
  String name;
  List<String> tasks;

  ProjectPhase({required this.name, required this.tasks});
}

class ProjectCreateScreen extends StatefulWidget {
  const ProjectCreateScreen({super.key});

  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();

  // 初期状態（標準テンプレート）
  final List<ProjectPhase> _phases = [
    ProjectPhase(name: '一次加工', tasks: ['ケガキ', '切断', '孔あけ', '開先加工', 'ショットブラスト']),
    ProjectPhase(name: 'コア部', tasks: ['野書', '組立', '溶接', '仕上']),
    ProjectPhase(name: '仕口部', tasks: ['野書', '組立', '溶接', '仕上']),
    ProjectPhase(name: '大組部', tasks: ['野書', '組立', '組立検査', '溶接', 'UT']),
  ];

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  // 汎用ダイアログ表示メソッド
  Future<String?> _showInputDialog({
    required String title,
    required String hintText,
    String? initialText,
  }) async {
    final controller = TextEditingController(text: initialText);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                Navigator.of(context).pop(text.isEmpty ? null : text);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ─── CRUD: 工程（親） ───
  Future<void> _addPhase() async {
    final name = await _showInputDialog(title: '新しい工程を追加', hintText: '工程名を入力');
    if (name != null) {
      setState(() {
        _phases.add(ProjectPhase(name: name, tasks: []));
      });
    }
  }

  Future<void> _editPhase(int phaseIndex) async {
    final phase = _phases[phaseIndex];
    final newName = await _showInputDialog(
      title: '工程名の編集',
      hintText: '工程名を入力',
      initialText: phase.name,
    );
    if (newName != null) {
      setState(() {
        phase.name = newName;
      });
    }
  }

  void _deletePhase(int phaseIndex) {
    setState(() {
      _phases.removeAt(phaseIndex);
    });
  }

  // ─── CRUD: 作業（子） ───
  Future<void> _addTask(int phaseIndex) async {
    final name = await _showInputDialog(title: '新しい作業を追加', hintText: '作業名を入力');
    if (name != null) {
      setState(() {
        _phases[phaseIndex].tasks.add(name);
      });
    }
  }

  Future<void> _editTask(int phaseIndex, int taskIndex) async {
    final taskName = _phases[phaseIndex].tasks[taskIndex];
    final newName = await _showInputDialog(
      title: '作業名の編集',
      hintText: '作業名を入力',
      initialText: taskName,
    );
    if (newName != null) {
      setState(() {
        _phases[phaseIndex].tasks[taskIndex] = newName;
      });
    }
  }

  void _deleteTask(int phaseIndex, int taskIndex) {
    setState(() {
      _phases[phaseIndex].tasks.removeAt(taskIndex);
    });
  }

  // ─── 保存アクション ───
  Future<void> _saveProject() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final projectName = _projectNameController.text.trim();
    if (_phases.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('工程を少なくとも1つ追加してください')));
      return;
    }

    // 保存中のUX: ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // 1. 新しい一意の projectId を生成（projects コレクションに保存）
      final projectRef = firestore.collection('projects').doc();
      final projectId = projectRef.id;

      batch.set(projectRef, {
        'name': projectName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. 階層データの保存手順 (tasks コレクション)
      // 仮の初期値（デフォルト値）
      final now = DateTime.now();
      final defaultStartDate = now;
      final defaultEndDate = now.add(const Duration(days: 30));

      final tasksCol = firestore.collection('tasks');

      for (var pIndex = 0; pIndex < _phases.length; pIndex++) {
        final phase = _phases[pIndex];

        // 親タスク（工程）の生成と保存
        final parentRef = tasksCol.doc();
        final parentId = parentRef.id;

        batch.set(parentRef, {
          'projectId': projectId,
          'parentId': null,
          'name': phase.name,
          'isSummary': true,
          'sortOrder': pIndex,
          'startDate': defaultStartDate,
          'endDate': defaultEndDate,
          'progress': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 子タスク（作業名）の生成と保存
        for (var tIndex = 0; tIndex < phase.tasks.length; tIndex++) {
          final taskName = phase.tasks[tIndex];
          final childRef = tasksCol.doc();

          batch.set(childRef, {
            'projectId': projectId,
            'parentId': parentId,
            'name': taskName,
            'isSummary': false,
            'sortOrder': tIndex,
            'startDate': defaultStartDate,
            'endDate': defaultEndDate,
            'progress': 0.0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // バッチ書き込みの実行
      await batch.commit();

      if (mounted) {
        // ローディングダイアログを閉じる
        Navigator.of(context).pop();
        // 前の画面へ戻る
        Navigator.of(context).pop();
        // 完了通知
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$projectName を新規登録しました')));
      }
    } catch (e) {
      if (mounted) {
        // ローディングダイアログを閉じる
        Navigator.of(context).pop();
        // エラー通知
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規物件登録 (テンプレート作成)'),
        actions: [
          TextButton.icon(
            onPressed: _saveProject,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 物件名入力エリア
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _projectNameController,
                    decoration: const InputDecoration(
                      labelText: '物件名',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '物件名を入力してください';
                      }
                      return null;
                    },
                  ),
                ),

                const Divider(height: 1),

                // 工程一覧ヘッダー
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '工程・作業テンプレート',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addPhase,
                        icon: const Icon(Icons.add),
                        label: const Text('工程を追加'),
                      ),
                    ],
                  ),
                ),

                // 工程リスト（ExpansionTile）
                Expanded(
                  child: ListView.builder(
                    itemCount: _phases.length,
                    itemBuilder: (context, phaseIndex) {
                      final phase = _phases[phaseIndex];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: ExpansionTile(
                          // 最初から展開状態にする場合は initiallyExpanded: true とするか検討
                          initiallyExpanded: true,
                          title: Text(
                            phase.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          leading: const Icon(Icons.folder),
                          // 工程レベルのアクション
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add_task),
                                tooltip: '作業を追加',
                                onPressed: () => _addTask(phaseIndex),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                tooltip: '工程名の編集',
                                onPressed: () => _editPhase(phaseIndex),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                tooltip: '工程の削除',
                                onPressed: () => _deletePhase(phaseIndex),
                              ),
                            ],
                          ),
                          // 作業レベルのリスト
                          children: [
                            if (phase.tasks.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  '作業が登録されていません',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: phase.tasks.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, indent: 48),
                                itemBuilder: (context, taskIndex) {
                                  final taskName = phase.tasks[taskIndex];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.only(
                                      left: 48,
                                      right: 8,
                                    ),
                                    title: Text('${taskIndex + 1}. $taskName'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                          ),
                                          tooltip: '作業の編集',
                                          onPressed: () =>
                                              _editTask(phaseIndex, taskIndex),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          tooltip: '作業の削除',
                                          onPressed: () => _deleteTask(
                                            phaseIndex,
                                            taskIndex,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            // 子リストの下に追加領域としてボタンを置くことも可能
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
