import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/project.dart';
import '../../../providers/project_providers.dart';
import '../../gantt/presentation/mock_legacy_gantt_screen.dart'
    show selectedProjectIdProvider;
import '../../tape_inspection/screens/tape_inspection_screen.dart';
import '../../witness_inspection/screens/witness_inspection_screen.dart';
import 'site_photo_list_screen.dart';
import 'blackboard_settings_screen.dart';
import 'template_list_screen.dart';

class PhotoTopScreen extends ConsumerWidget {
  const PhotoTopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final projects = projectsAsync.valueOrNull ?? [];

    if (projects.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('工程写真トップ')),
        body: const Center(child: Text('プロジェクトがありません')),
      );
    }

    final selectedId = ref.watch(selectedProjectIdProvider);
    final selectedProject =
        projects.where((p) => p.id == selectedId).firstOrNull ?? projects.first;

    return Scaffold(
      appBar: AppBar(title: const Text('工程写真トップ')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左ペイン: メニューエリア
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 工事名選択用の DropdownButton
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedProject.id,
                    items: projects.map((Project p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(selectedProjectIdProvider.notifier).state =
                            value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 黒板テンプレートのサマリーを表示するダミーの Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '2026/03/05 | 晴れ | 撮影者：未定',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 縦並びのボタン群
                  // 1. 工程写真 (メインアクション・サイズ大)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SitePhotoListScreen(
                            projectName: selectedProject.name,
                            projectId: selectedProject.id,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(70),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('工程写真'),
                  ),
                  const SizedBox(height: 16),

                  // 2. 立会検査写真 と 3. テープ合わせ (横並び)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WitnessInspectionScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('立会検査写真'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TapeInspectionScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('テープ合わせ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. 是正写真 (警告色・アウトライン)
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text('是正写真'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. 黒板設定
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlackboardSettingsScreen(
                            projectName: selectedProject.name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('黒板設定'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: Colors.grey[800],
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 【テスト用】テンプレート作成画面へ
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TemplateListScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'テンプレート管理画面へ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 右ペイン: 撮影履歴の確認エリア
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[200],
              child: const Center(child: Text('ここに撮影履歴リストを表示します')),
            ),
          ),
        ],
      ),
    );
  }
}
