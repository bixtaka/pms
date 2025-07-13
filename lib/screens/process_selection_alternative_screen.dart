import 'package:flutter/material.dart';

class ProcessSelectionAlternativeScreen extends StatefulWidget {
  const ProcessSelectionAlternativeScreen({Key? key}) : super(key: key);

  @override
  State<ProcessSelectionAlternativeScreen> createState() => _ProcessSelectionAlternativeScreenState();
}

class _ProcessSelectionAlternativeScreenState extends State<ProcessSelectionAlternativeScreen> {
  String? selectedMainProcess;
  
  // チェックボックスの状態管理
  final Map<String, Map<String, bool>> checkboxStates = {};
  
  // 中項目と小項目のデータ
  final Map<String, List<String>> processData = {
    '一次加工': ['材料入荷', '切断', '孔あけ', '面取り', '研磨', '熱処理', '表面処理', '洗浄'],
    '組立': ['部品組み立て', '溶接', '接着', '締結', '調整', '配線', '配管', 'テスト'],
    '検査': ['外観検査', '寸法検査', '機能検査', '耐久性検査', '最終検査', '性能試験', '安全性検査'],
  };

  @override
  void initState() {
    super.initState();
    // チェックボックスの初期状態を設定
    for (var mainProcess in processData.keys) {
      checkboxStates[mainProcess] = {};
      for (var subProcess in processData[mainProcess]!) {
        checkboxStates[mainProcess]![subProcess] = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工程選択（代替案）'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$selectedMainProcessの小項目',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // 全選択/全解除ボタン
                  Row(
                    children: [
                      TextButton(
                        onPressed: _selectAll,
                        child: const Text('全選択'),
                      ),
                      TextButton(
                        onPressed: _deselectAll,
                        child: const Text('全解除'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 固定高さのコンテナ + ListView
              Container(
                height: 400, // 固定高さを設定
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: processData[selectedMainProcess]!.length,
                  itemBuilder: (context, index) {
                    final subProcess = processData[selectedMainProcess]![index];
                    final isChecked = checkboxStates[selectedMainProcess]![subProcess] ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: CheckboxListTile(
                        title: Text(subProcess),
                        value: isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            checkboxStates[selectedMainProcess]![subProcess] = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        activeColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 選択された項目のサマリー
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '選択された項目',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._getSelectedItems().map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    )),
                    if (_getSelectedItems().isEmpty)
                      const Text(
                        '選択された項目はありません',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // 中項目が選択されていない場合の表示
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
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

  // 全選択
  void _selectAll() {
    if (selectedMainProcess != null) {
      setState(() {
        for (var subProcess in processData[selectedMainProcess]!) {
          checkboxStates[selectedMainProcess]![subProcess] = true;
        }
      });
    }
  }

  // 全解除
  void _deselectAll() {
    if (selectedMainProcess != null) {
      setState(() {
        for (var subProcess in processData[selectedMainProcess]!) {
          checkboxStates[selectedMainProcess]![subProcess] = false;
        }
      });
    }
  }

  // 選択された項目を取得
  List<String> _getSelectedItems() {
    final selectedItems = <String>[];
    
    for (var mainProcess in processData.keys) {
      for (var subProcess in processData[mainProcess]!) {
        if (checkboxStates[mainProcess]![subProcess] == true) {
          selectedItems.add('$mainProcess - $subProcess');
        }
      }
    }
    
    return selectedItems;
  }
} 