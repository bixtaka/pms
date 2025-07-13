import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';
import '../widgets/gantt_chart_widget.dart';
import '../widgets/work_type_gantt_widget.dart';
import 'progress_input_screen.dart';
import '../widgets/process_step_selector.dart';

enum GanttViewMode { day, week, month, quarter, halfYear }

enum GanttType { product, workType }

class ProductionManagementScreen extends StatefulWidget {
  const ProductionManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProductionManagementScreen> createState() =>
      _ProductionManagementScreenState();
}

class _ProductionManagementScreenState
    extends State<ProductionManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  GanttViewMode _currentViewMode = GanttViewMode.week;
  GanttType _currentGanttType = GanttType.product;
  late DateTime startDate;
  late DateTime endDate;
  
  // 工程選択状態を管理
  String? selectedProcess;

  // 工程データ構造
  final Map<String, List<String>> processSteps = {
    "一次加工": ["材料入荷", "孔あけ", "切断", "開先加工", "ショットブラスト"],
    "組立": ["仮組立", "本組立", "溶接"],
    "検査": ["外観", "寸法", "超音波検査"]
  };

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_currentViewMode) {
      case GanttViewMode.day:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case GanttViewMode.week:
        startDate = now.subtract(const Duration(days: 3));
        endDate = now.add(const Duration(days: 3));
        break;
      case GanttViewMode.month:
        startDate = now.subtract(const Duration(days: 15));
        endDate = now.add(const Duration(days: 15));
        break;
      case GanttViewMode.quarter:
        startDate = now.subtract(const Duration(days: 45));
        endDate = now.add(const Duration(days: 45));
        break;
      case GanttViewMode.halfYear:
        startDate = now.subtract(const Duration(days: 90));
        endDate = now.add(const Duration(days: 90));
        break;
    }
  }

  String _getViewModeText(GanttViewMode mode) {
    switch (mode) {
      case GanttViewMode.day:
        return '1日';
      case GanttViewMode.week:
        return '1週間';
      case GanttViewMode.month:
        return '1か月';
      case GanttViewMode.quarter:
        return '3か月';
      case GanttViewMode.halfYear:
        return '6か月';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生産管理システム'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          ElevatedButton.icon(
            onPressed: _addSampleData,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'サンプルデータ追加',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'メニュー',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('進捗入力'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProgressInputScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サンプルデータ追加欄を削除
            // 工種別進捗サマリー
            _buildProgressSummary(),
            const SizedBox(height: 20),
            // ガントチャートタイトル・期間・セレクタ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ガントチャート',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      '${startDate.month}/${startDate.day} 〜 ${endDate.month}/${endDate.day}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildViewModeSelector(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // タブ
            _buildGanttTypeTabs(),
            const SizedBox(height: 8),
            // タブの下の中身
            Expanded(
              child: _currentGanttType == GanttType.product
                  ? SingleChildScrollView(
                      child: _buildGanttChart(),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProcessStepSelector(
                          onProcessChanged: (String process) {
                            // 選択された工程に応じてガントチャートを更新
                            setState(() {
                              selectedProcess = process.isEmpty ? null : process;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: WorkTypeGanttWidget(
                            workTypeData: [], // 必要に応じてデータを渡す
                            startDate: startDate,
                            endDate: endDate,
                            selectedProcess: selectedProcess,
                            processSteps: processSteps,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ガントチャートタイプ切り替えタブ
  Widget _buildGanttTypeTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentGanttType = GanttType.product;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _currentGanttType == GanttType.product
                      ? Colors.blue
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: Center(
                  child: Text(
                    '製品別',
                    style: TextStyle(
                      color: _currentGanttType == GanttType.product
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentGanttType = GanttType.workType;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _currentGanttType == GanttType.workType
                      ? Colors.blue
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Center(
                  child: Text(
                    '工種別',
                    style: TextStyle(
                      color: _currentGanttType == GanttType.workType
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 表示期間選択ウィジェット
  Widget _buildViewModeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<GanttViewMode>(
          value: _currentViewMode,
          items: GanttViewMode.values.map((mode) {
            return DropdownMenuItem<GanttViewMode>(
              value: mode,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(_getViewModeText(mode)),
              ),
            );
          }).toList(),
          onChanged: (GanttViewMode? newValue) {
            if (newValue != null) {
              setState(() {
                _currentViewMode = newValue;
                _updateDateRange();
              });
            }
          },
        ),
      ),
    );
  }

  // 工種別進捗サマリー
  Widget _buildProgressSummary() {
    return StreamBuilder<Map<String, Map<String, int>>>(
      stream: _firebaseService.getProgressSummaryStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('エラー: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('進捗データがありません'));
        }
        final summary = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 120),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '工種別進捗',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...summary.entries.map((entry) {
                final type = entry.key;
                final data = entry.value;
                final total = data['total'] ?? 0;
                final completed = data['completed'] ?? 0;
                final inProgress = data['in_progress'] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          type,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('完成$completed/$total'),
                      const SizedBox(width: 16),
                      Text('作業中$inProgress'),
                      const SizedBox(width: 16),
                      Text('未着手${total - completed - inProgress}'),
                    ],
                  ),
                );
              }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ガントチャート
  Widget _buildGanttChart() {
    if (_currentGanttType == GanttType.product) {
      return StreamBuilder<List<Product>>(
        stream: _firebaseService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('エラー:  [${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ガントチャート用データがありません'));
          }
          return GanttChartWidget(
            products: snapshot.data!,
            startDate: startDate,
            endDate: endDate,
          );
        },
      );
    } else {
      // 工種別タブのとき、ProcessStepSelectorを上部に表示
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProcessStepSelector(
            onProcessChanged: (String process) {
              // 選択された工程に応じてガントチャートを更新
              setState(() {
                selectedProcess = process.isEmpty ? null : process;
              });
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: StreamBuilder<List<WorkTypeGanttData>>(
              stream: _firebaseService.getWorkTypeGanttStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('エラー: [ [${snapshot.error}]'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('工種別ガントチャート用データがありません'));
                }
                return WorkTypeGanttWidget(
                  workTypeData: snapshot.data!,
                  startDate: startDate,
                  endDate: endDate,
                  selectedProcess: selectedProcess,
                  processSteps: processSteps,
                );
              },
            ),
          ),
        ],
      );
    }
  }

  // 製品リスト
  Widget _buildProductList() {
    return StreamBuilder<List<Product>>(
      stream: _firebaseService.getProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('エラー: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('製品データがありません'));
        }
        final products = snapshot.data!;
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(product.name),
                subtitle: Text('種類: ${product.type}'),
                trailing: _buildStatusButton(product),
                leading: _buildStatusIcon(product.status),
              ),
            );
          },
        );
      },
    );
  }

  // 状態ボタン
  Widget _buildStatusButton(Product product) {
    String buttonText;
    Color buttonColor;

    switch (product.status) {
      case 'not_started':
        buttonText = '開始';
        buttonColor = Colors.blue;
        break;
      case 'in_progress':
        buttonText = '完了';
        buttonColor = Colors.green;
        break;
      case 'completed':
        buttonText = '完了済み';
        buttonColor = Colors.grey;
        break;
      default:
        buttonText = '開始';
        buttonColor = Colors.blue;
    }

    return ElevatedButton(
      onPressed: product.status == 'completed'
          ? null
          : () => _updateStatus(product),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
      ),
      child: Text(buttonText),
    );
  }

  // 状態アイコン
  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color iconColor;

    switch (status) {
      case 'completed':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'in_progress':
        iconData = Icons.pending;
        iconColor = Colors.orange;
        break;
      case 'not_started':
        iconData = Icons.radio_button_unchecked;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.radio_button_unchecked;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor);
  }

  // 状態更新
  void _updateStatus(Product product) {
    String newStatus;

    switch (product.status) {
      case 'not_started':
        newStatus = 'in_progress';
        break;
      case 'in_progress':
        newStatus = 'completed';
        break;
      default:
        return;
    }

    _firebaseService.updateProductStatus(product.id, newStatus);
  }

  // サンプルデータ追加
  void _addSampleData() async {
    try {
      await _firebaseService.addSampleData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('サンプルデータを追加しました')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラー: $e')));
    }
  }
}
