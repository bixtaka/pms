import 'package:flutter/material.dart';

class ProcessStepSelector extends StatefulWidget {
  const ProcessStepSelector({Key? key}) : super(key: key);

  @override
  State<ProcessStepSelector> createState() => _ProcessStepSelectorState();
}

class _ProcessStepSelectorState extends State<ProcessStepSelector> {
  // 工程データ
  final Map<String, List<String>> processSteps = {
    "一次加工": ["材料入荷", "孔あけ", "切断", "開先加工", "ショットブラスト"],
    "組立": ["仮組立", "本組立", "溶接", "歪み取り"],
    "検査": ["外観検査", "寸法検査", "超音波検査"],
  };

  // 選択中の中項目
  late String selectedCategory;
  // 小項目のチェック状態
  Map<String, bool> checkedSteps = {};

  @override
  void initState() {
    super.initState();
    selectedCategory = processSteps.keys.first; // 最初は「一次加工」
    // 小項目の初期化
    for (var steps in processSteps.values) {
      for (var step in steps) {
        checkedSteps[step] = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = processSteps.keys.toList();
    final steps = processSteps[selectedCategory]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 中項目ボタン群
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((category) {
              final isSelected = category == selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Colors.blue
                        : Colors.grey[200],
                    foregroundColor: isSelected ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Text(category),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // 小項目リスト
        ...steps.map(
          (step) => Card(
            child: ListTile(
              title: Text(step),
              trailing: Checkbox(
                value: checkedSteps[step] ?? false,
                onChanged: (val) {
                  setState(() {
                    checkedSteps[step] = val ?? false;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  checkedSteps[step] = !(checkedSteps[step] ?? false);
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
