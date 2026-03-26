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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('工程写真トップ'),
          bottom: MediaQuery.of(context).size.width >= 600
              ? null
              : const TabBar(
                  tabs: [
                    Tab(text: 'メニュー', icon: Icon(Icons.menu)),
                    Tab(text: '撮影履歴', icon: Icon(Icons.history)),
                  ],
                ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            if (isWide) {
              // --- iPad（横表示）: 左右分割 ---
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildWideMenuColumn(
                      context,
                      ref,
                      selectedProject,
                      projects,
                    ),
                  ),
                  Expanded(flex: 2, child: _buildHistoryArea()),
                ],
              );
            } else {
              // --- iPhone（縦表示）: タブ切り替え ---
              return TabBarView(
                children: [
                  _buildNarrowMenuGrid(context, ref, selectedProject, projects),
                  _buildHistoryArea(),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  /// iPad用の左側メニュー（縦に並ぶ）
  Widget _buildWideMenuColumn(
    BuildContext context,
    WidgetRef ref,
    Project selectedProject,
    List<Project> projects,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProjectDropdown(ref, selectedProject, projects),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildMenuCard(
                  context,
                  title: '工程写真',
                  icon: Icons.camera_alt,
                  iconColor: Theme.of(context).primaryColor,
                  onTap: () => _goToPhotoList(context, selectedProject),
                ),
                _buildMenuCard(
                  context,
                  title: '立会検査写真',
                  icon: Icons.assignment_turned_in,
                  iconColor: Colors.teal,
                  onTap: () => _goToWitness(context),
                ),
                _buildMenuCard(
                  context,
                  title: 'テープ合わせ',
                  icon: Icons.straighten,
                  iconColor: Colors.deepPurple,
                  onTap: () => _goToTape(context),
                ),
                _buildMenuCard(
                  context,
                  title: '是正写真',
                  icon: Icons.warning_amber_rounded,
                  iconColor: Colors.red,
                  onTap: () {},
                ),
                _buildMenuCard(
                  context,
                  title: '黒板設定',
                  icon: Icons.settings,
                  iconColor: Colors.grey[700]!,
                  onTap: () => _goToBlackboard(context, selectedProject),
                ),
                _buildMenuCard(
                  context,
                  title: 'テンプレート管理画面',
                  icon: Icons.edit_document,
                  iconColor: Colors.orange,
                  onTap: () => _goToTemplateList(context),
                ),
                _buildSummaryCard(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// iPhone用のグリッドメニュー
  Widget _buildNarrowMenuGrid(
    BuildContext context,
    WidgetRef ref,
    Project selectedProject,
    List<Project> projects,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildProjectDropdown(ref, selectedProject, projects),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: const EdgeInsets.all(8),
            childAspectRatio: 1.5,
            children: [
              _buildSmallMenuCard(
                context,
                title: '工程写真',
                icon: Icons.camera_alt,
                color: Colors.blue,
                onTap: () => _goToPhotoList(context, selectedProject),
              ),
              _buildSmallMenuCard(
                context,
                title: '立会検査',
                icon: Icons.check_circle,
                color: Colors.teal,
                onTap: () => _goToWitness(context),
              ),
              _buildSmallMenuCard(
                context,
                title: 'テープ',
                icon: Icons.straighten,
                color: Colors.purple,
                onTap: () => _goToTape(context),
              ),
              _buildSmallMenuCard(
                context,
                title: '是正',
                icon: Icons.warning,
                color: Colors.red,
                onTap: () {},
              ),
              _buildSmallMenuCard(
                context,
                title: '黒板設定',
                icon: Icons.settings,
                color: Colors.grey,
                onTap: () => _goToBlackboard(context, selectedProject),
              ),
              _buildSmallMenuCard(
                context,
                title: '管理画面',
                icon: Icons.edit,
                color: Colors.orange,
                onTap: () => _goToTemplateList(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// プロジェクト選択のドロップダウン
  Widget _buildProjectDropdown(
    WidgetRef ref,
    Project selectedProject,
    List<Project> projects,
  ) {
    return DropdownButton<String>(
      isExpanded: true,
      value: selectedProject.id,
      items: projects
          .map(
            (Project p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null)
          ref.read(photoSelectedProjectIdProvider.notifier).state = value;
      },
    );
  }

  /// 撮影履歴エリア（共通）
  Widget _buildHistoryArea() {
    return Container(
      color: Colors.grey[200],
      child: const Center(child: Text('ここに撮影履歴リストを表示します')),
    );
  }

  /// サマリーカード
  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '2026/03/05 | 晴れ | 撮影者：未定',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  // --- 画面遷移用のメソッド（整理しました） ---
  void _goToPhotoList(BuildContext context, Project p) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SitePhotoListScreen(projectName: p.name, projectId: p.id),
    ),
  );
  void _goToWitness(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WitnessInspectionScreen()),
  );
  void _goToTape(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TapeInspectionScreen()),
  );
  void _goToBlackboard(BuildContext context, Project p) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BlackboardSettingsScreen(projectName: p.name),
    ),
  );
  void _goToTemplateList(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TemplateListScreen()),
  );

  /// iPad用メニューカード
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }

  /// iPhone用メニュータイル
  Widget _buildSmallMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
