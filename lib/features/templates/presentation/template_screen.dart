import 'package:flutter/material.dart';

class TemplateScreen extends StatelessWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('テンプレート')),
      body: const Center(child: Text('テンプレート画面（作成中）')),
    );
  }
}
