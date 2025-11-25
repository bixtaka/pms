import 'package:flutter/material.dart';
import 'features/projects/presentation/project_list_screen.dart';

/// アプリ全体の MaterialApp 定義
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMS',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const ProjectListScreen(),
    );
  }
}
