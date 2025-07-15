import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/production_management_screen.dart';
import 'package:provider/provider.dart';
import 'models/work_type_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化（簡易版）
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase設定が不完全な場合はデフォルト設定で初期化
    await Firebase.initializeApp();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => WorkTypeState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '生産管理システム',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ProductionManagementScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
