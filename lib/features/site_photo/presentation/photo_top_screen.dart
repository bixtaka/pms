import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../projects/domain/project.dart';
import '../../projects/application/project_providers.dart';

import '../../tape_inspection/presentation/tape_inspection_screen.dart';
import '../../witness_inspection/presentation/witness_inspection_screen.dart';
import 'site_photo_list_screen.dart';
import 'blackboard_settings_screen.dart';
import 'template_list_screen.dart';

/// 工程写真トップ画面専用の選択中のプロジェクトIDプロバイダー
final photoSelectedProjectIdProvider = StateProvider<String?>((ref) => null);

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

    final selectedId = ref.watch(photoSelectedProjectIdProvider);
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
                        ref.read(photoSelectedProjectIdProvider.notifier).state =
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

                  // 縦並びのメニューリスト
                  Expanded(
                    child: ListView(
                      children: [
                        // 1. 工程写真 (メインアクション・ハイライト)
                        _buildMenuCard(
                          context,
                          title: '工程写真',
                          icon: Icons.camera_alt,
                          iconColor: Theme.of(context).primaryColor,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.05),
                          onTap: () {
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
                        ),
                        
                        // 2. 立会検査写真
                        _buildMenuCard(
                          context,
                          title: '立会検査写真',
                          icon: Icons.assignment_turned_in,
                          iconColor: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WitnessInspectionScreen(),
                              ),
                            );
                          },
                        ),

                        // 3. テープ合わせ
                        _buildMenuCard(
                          context,
                          title: 'テープ合わせ',
                          icon: Icons.straighten,
                          iconColor: Colors.deepPurple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TapeInspectionScreen(),
                              ),
                            );
                          },
                        ),

                        // 4. 是正写真
                        _buildMenuCard(
                          context,
                          title: '是正写真',
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.red,
                          onTap: () {},
                        ),

                        // 5. 黒板設定
                        _buildMenuCard(
                          context,
                          title: '黒板設定',
                          icon: Icons.settings,
                          iconColor: Colors.grey[700]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlackboardSettingsScreen(
                                  projectName: selectedProject.name,
                                ),
                              ),
                            );
                          },
                        ),

                        // 6. テンプレート管理画面へ
                        _buildMenuCard(
                          context,
                          title: 'テンプレート管理画面',
                          icon: Icons.edit_document,
                          iconColor: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TemplateListScreen(),
                              ),
                            );
                          },
                        ),
                      ],
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

  /// メニュー項目用の共通カードUI
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: backgroundColor ?? Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }
}
