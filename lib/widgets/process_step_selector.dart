import 'package:flutter/material.dart';

class ProcessStepSelector extends StatefulWidget {
  final Function(String) onProcessChanged;
  
  const ProcessStepSelector({
    Key? key,
    required this.onProcessChanged,
  }) : super(key: key);

  @override
  State<ProcessStepSelector> createState() => _ProcessStepSelectorState();
}

class _ProcessStepSelectorState extends State<ProcessStepSelector> {
  // 工程データ構造（拡張性を考慮）
  final Map<String, List<String>> processSteps = {
    "一次加工": ["材料入荷", "孔あけ", "切断", "開先加工", "ショットブラスト"],
    "組立": ["仮組立", "本組立", "溶接"],
    "検査": ["外観", "寸法", "超音波検査"]
  };

  String? selectedProcess; // 選択中の工程

  @override
  void initState() {
    super.initState();
    selectedProcess = null; // 初期状態では何も選択されていない
  }

  @override
  Widget build(BuildContext context) {
    final categories = processSteps.keys.toList();

    return Row(
      children: categories.map((category) {
        final isSelected = category == selectedProcess;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
              foregroundColor: isSelected ? Colors.white : Colors.black87,
              side: BorderSide(
                color: isSelected ? Colors.blue : Colors.grey[400]!,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            onPressed: () {
              setState(() {
                // 同じボタンを押した場合は選択解除、異なるボタンの場合は切り替え
                selectedProcess = selectedProcess == category ? null : category;
              });
              // 親ウィジェットに選択状態を通知
              widget.onProcessChanged(selectedProcess ?? '');
            },
            child: Text(category),
          ),
        );
      }).toList(),
    );
  }

  // 現在選択されている工程を取得
  String? getSelectedProcess() => selectedProcess;
  
  // 選択されている工程の小項目リストを取得
  List<String> getSelectedSteps() {
    if (selectedProcess == null || !processSteps.containsKey(selectedProcess)) {
      return [];
    }
    return processSteps[selectedProcess]!;
  }

  // 全工程の小項目リストを取得（将来の拡張用）
  Map<String, List<String>> getAllProcessSteps() => processSteps;
}
