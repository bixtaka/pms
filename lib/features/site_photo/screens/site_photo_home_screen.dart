// site_photo_home_screen.dart
// 工程写真機能のホーム画面
// カメラ画面への遷移ボタンを配置

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'site_photo_list_screen.dart';  // リスト画面をインポート
import 'blackboard_settings_screen.dart';  // 黒板設定画面をインポート

/// 工程写真機能のホーム画面
/// 
/// この画面から電子小黒板付きカメラ画面へ遷移できます。
class SitePhotoHomeScreen extends StatelessWidget {
  const SitePhotoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景色（Apple風のライトグレー）
      backgroundColor: const Color(0xFFF2F2F7),
      
      // アプリバー
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        title: const Text(
          '工程写真',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      
      // 本体部分
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === 説明カード ===
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          color: Color(0xFF007AFF),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '電子小黒板について',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '電子小黒板を使用すると、工事名・撮影日・工種などの情報を写真に直接記録できます。撮影ボタンを押すと、黒板情報が写真に合成されます。',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // === カメラ起動ボタン ===
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _navigateToCameraScreen(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34C759), Color(0xFF30B350)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(52, 199, 89, 0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.camera_fill,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'カメラを起動する',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // === 黒板設定ボタン ===
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _navigateToSettings(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5E5EA),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.settings,
                        color: Color(0xFF007AFF),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        '黒板設定',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // === 写真一覧ボタン（将来の機能用） ===
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // TODO: 写真一覧画面への遷移（将来実装）
                  debugPrint('📷 写真一覧ボタンが押されました');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5E5EA),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.photo_on_rectangle,
                        color: Color(0xFF007AFF),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        '撮影した写真を見る',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // === ヒントテキスト ===
              const Center(
                child: Text(
                  'iPad の背面カメラで撮影します',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black38,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 撮影リスト画面へ遷移する
  void _navigateToCameraScreen(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const SitePhotoListScreen(
          // === サンプルデータを渡す ===
          projectName: 'Aマンション改修工事',  // 工事名
          projectId: 'demo_project_001',      // 工事ID (Firestore用)
        ),
      ),
    );
  }

  /// 黒板設定画面へ遷移する
  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const BlackboardSettingsScreen(
          projectName: 'Aマンション改修工事', // サンプルプロジェクト名
        ),
      ),
    );
  }
}
