import 'package:flutter/material.dart';

class ProcessSelectionAdvancedScreen extends StatefulWidget {
  const ProcessSelectionAdvancedScreen({super.key});

  @override
  State<ProcessSelectionAdvancedScreen> createState() => _ProcessSelectionAdvancedScreenState();
}

class _ProcessSelectionAdvancedScreenState extends State<ProcessSelectionAdvancedScreen> {
  String? selectedMainProcess;
  
  // チェックボックスの状態管理
  final Map<String, Map<String, bool>> checkboxStates = {};
  
  // 中項目と小項目のデータ
  final Map<String, List<String>> processData = {
    '一次加工': ['材料入荷', '切断', '孔あけ', '面取り', '研磨', '熱処理', '表面処理'],
    '組立': ['部品組み立て', '溶接', '接着', '締結', '調整', '配線', '配管'],
    '検査': ['外観検査', '寸法検査', '機能検査', '耐久性検査', '最終検査', '性能試験'],
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
        title: const Text('工程選択（改良版）'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // 選択された項目を表示するボタン
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: _showSelectedItems,
          ),
        ],
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

  // 選択された項目を表示
  void _showSelectedItems() {
    final selectedItems = <String>[];
    
    for (var mainProcess in processData.keys) {
      for (var subProcess in processData[mainProcess]!) {
        if (checkboxStates[mainProcess]![subProcess] == true) {
          selectedItems.add('$mainProcess - $subProcess');
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選択された項目'),
        content: SizedBox(
          width: double.maxFinite,
          child: selectedItems.isEmpty
              ? const Text('選択された項目はありません')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: selectedItems.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.check, color: Colors.green),
                      title: Text(selectedItems[index]),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
} 