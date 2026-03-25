import 'package:flutter/material.dart';

class ProcessSelectionScreen extends StatefulWidget {
  const ProcessSelectionScreen({super.key});

  @override
  State<ProcessSelectionScreen> createState() => _ProcessSelectionScreenState();
}

class _ProcessSelectionScreenState extends State<ProcessSelectionScreen> {
  String? selectedMainProcess;
  
  // 中項目と小項目のデータ
  final Map<String, List<String>> processData = {
    '一次加工': ['材料入荷', '切断', '孔あけ', '面取り', '研磨'],
    '組立': ['部品組み立て', '溶接', '接着', '締結', '調整'],
    '検査': ['外観検査', '寸法検査', '機能検査', '耐久性検査', '最終検査'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工程選択'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 中項目ボタン
            const Text(
              '中項目を選択してください',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 中項目ボタン行
            Row(
              children: processData.keys.map((mainProcess) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedMainProcess = mainProcess;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedMainProcess == mainProcess
                            ? Colors.blue
                            : Colors.grey.shade300,
                        foregroundColor: selectedMainProcess == mainProcess
                            ? Colors.white
                            : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        mainProcess,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // 小項目リスト
            if (selectedMainProcess != null) ...[
              Text(
                '$selectedMainProcessの小項目',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Expanded + ListView でスクロール可能なリスト
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: processData[selectedMainProcess]!.length,
                    itemBuilder: (context, index) {
                      final subProcess = processData[selectedMainProcess]![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: CheckboxListTile(
                          title: Text(subProcess),
                          value: false, // ここで状態管理
                          onChanged: (bool? value) {
                            // チェックボックスの状態を更新
                            setState(() {
                              // 実際のアプリでは状態管理を実装
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              // 中項目が選択されていない場合の表示
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '中項目を選択してください',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 