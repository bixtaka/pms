import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';
import '../widgets/work_type_gantt_widget.dart';
import 'progress_input_screen.dart';
import 'bulk_progress_input_screen.dart';
import '../widgets/process_step_selector.dart';
import 'package:provider/provider.dart';
import '../models/work_type_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum GanttViewMode { day, week, month, quarter, halfYear }

enum GanttType { product, workType }

class ProductionManagementScreen extends StatefulWidget {
  const ProductionManagementScreen({super.key});

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

  bool _isAddingSample = false;

  // 工程選択状態を管理
  String? selectedProcess;

  // 製品カテゴリ選択状態を追加
  String selectedCategory = '一次加工';

  // 並び順状態を追加
  bool isAscending = true;

  // 展開中のセル（製品ID＋工種名）
  String? expandedProductId;
  String? expandedProcessName;

  // 工程データ構造
  final Map<String, List<String>> processSteps = {
    "一次加工": ["材料入荷", "孔あけ", "切断", "開先加工", "ショットブラスト"],
    "組立": ["仮組立", "本組立", "溶接"],
    "検査": ["外観", "寸法", "超音波検査"],
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
            onPressed: _isAddingSample
                ? null
                : () async {
                    setState(() => _isAddingSample = true);
                    try {
                      await _firebaseService.addSampleData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('サンプルデータを追加しました')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('エラー: $e')));
                    } finally {
                      setState(() => _isAddingSample = false);
                    }
                  },
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
          ElevatedButton.icon(
            onPressed: _isAddingSample
                ? null
                : () async {
                    setState(() => _isAddingSample = true);
                    try {
                      // 全製品に部材サンプルを追加
                      final products = await _firebaseService
                          .getProductsStream()
                          .first;
                      for (final product in products) {
                        await _firebaseService.addSampleParts(product.id);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('全製品に部材サンプルを追加しました')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('エラー: $e')));
                    } finally {
                      setState(() => _isAddingSample = false);
                    }
                  },
            icon: const Icon(Icons.add_box, color: Colors.white),
            label: const Text(
              '部材サンプル一括追加',
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
            // 進捗状況一括入力ボタン
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BulkProgressInputScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  '進捗状況一括入力',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            // タブ
            _buildGanttTypeTabs(),
            const SizedBox(height: 8),
            // タブの下の中身
            Expanded(
              child: _currentGanttType == GanttType.product
                  ? _buildProductGanttView()
                  : _buildWorkTypeGanttView(),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                      }),
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

  // 製品別ガントチャートビュー
  Widget _buildProductGanttView() {
    final workTypeState = Provider.of<WorkTypeState>(context);
    final processNames = workTypeState.processList;
    final selectedCategory = workTypeState.selectedCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 製品カテゴリボタン
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    workTypeState.setCategory('一次加工');
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selectedCategory == '一次加工'
                        ? Colors.orange.shade400
                        : Colors.grey.shade200,
                    foregroundColor: selectedCategory == '一次加工'
                        ? Colors.white
                        : Colors.grey,
                    side: BorderSide(
                      color: selectedCategory == '一次加工'
                          ? Colors.orange.shade400
                          : Colors.grey.shade400,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '一次加工',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    workTypeState.setCategory('柱');
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selectedCategory == '柱'
                        ? Colors.blue.shade400
                        : Colors.grey.shade200,
                    foregroundColor: selectedCategory == '柱'
                        ? Colors.white
                        : Colors.grey,
                    side: BorderSide(
                      color: selectedCategory == '柱'
                          ? Colors.blue.shade400
                          : Colors.grey.shade400,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '柱',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    workTypeState.setCategory('梁・間柱');
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selectedCategory == '梁・間柱'
                        ? Colors.green.shade400
                        : Colors.grey.shade200,
                    foregroundColor: selectedCategory == '梁・間柱'
                        ? Colors.white
                        : Colors.grey,
                    side: BorderSide(
                      color: selectedCategory == '梁・間柱'
                          ? Colors.green.shade400
                          : Colors.grey.shade400,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '梁・間柱',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 並び替えドロップダウン
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              const Text('製品名で並び替え：'),
              const SizedBox(width: 8),
              DropdownButton<bool>(
                value: isAscending,
                items: const [
                  DropdownMenuItem(value: true, child: Text('昇順')),
                  DropdownMenuItem(value: false, child: Text('降順')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      isAscending = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        // 製品リスト＋工種名ラベル（表形式）
        Expanded(
          child: StreamBuilder<List<Product>>(
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
              // カテゴリに応じて製品を絞り込み
              List<Product> filteredProducts;
              if (selectedCategory == '柱') {
                filteredProducts = products
                    .where((p) => p.processCategory == '柱')
                    .toList();
              } else if (selectedCategory == '梁・間柱') {
                filteredProducts = products
                    .where(
                      (p) =>
                          p.processCategory == '大梁' ||
                          p.processCategory == '小梁' ||
                          p.processCategory == '間柱',
                    )
                    .toList();
              } else {
                filteredProducts = products;
              }
              // 並び順でソート
              filteredProducts.sort(
                (a, b) => isAscending
                    ? a.name.compareTo(b.name)
                    : b.name.compareTo(a.name),
              );
              // ラベル行＋データ行を作成
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.grey),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: FixedColumnWidth(120),
                    for (int i = 1; i <= 20; i++) i: FixedColumnWidth(80),
                  },
                  children: [
                    // ラベル行
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            '製品名',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...processNames.map(
                          (p) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              p,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // データ行
                    ...filteredProducts.expand((product) {
                      return [
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(product.name),
                            ),
                            ...processNames.map(
                              (processName) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (expandedProductId == product.id &&
                                        expandedProcessName == processName) {
                                      expandedProductId = null;
                                      expandedProcessName = null;
                                    } else {
                                      expandedProductId = product.id;
                                      expandedProcessName = processName;
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: FutureBuilder<Map<String, dynamic>?>(
                                    future: _firebaseService
                                        .getProductProcessProgress(
                                          productId: product.id,
                                          processName: processName,
                                        ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }
                                      final data = snapshot.data;
                                      if (data == null) {
                                        return const SizedBox.shrink();
                                      }
                                      // 状態に応じた背景色
                                      Color bgColor;
                                      switch (data['status']) {
                                        case 'completed':
                                          bgColor = Colors.green.shade200;
                                          break;
                                        case 'in_progress':
                                          bgColor = Colors.orange.shade200;
                                          break;
                                        case 'not_started':
                                        default:
                                          bgColor = Colors.grey.shade200;
                                      }
                                      // 日付
                                      String dateStr = '';
                                      if (data['date'] != null) {
                                        final date = (data['date'] as Timestamp)
                                            .toDate();
                                        dateStr =
                                            '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
                                      }
                                      // 担当者
                                      final person = data['person'] ?? '';
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            if (dateStr.isNotEmpty) ...[
                                              Text(
                                                dateStr,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                            // 担当者（person）は非表示にするため削除
                                            // if (person.isNotEmpty) ...[
                                            //   const SizedBox(width: 4),
                                            //   Text(
                                            //     person,
                                            //     style: const TextStyle(
                                            //       fontSize: 10,
                                            //       color: Colors.grey,
                                            //     ),
                                            //   ),
                                            // ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (expandedProductId == product.id &&
                            expandedProcessName != null)
                          TableRow(
                            children: [
                              const SizedBox.shrink(),
                              ...processNames.map((processName) {
                                if (expandedProcessName == processName) {
                                  return Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child:
                                        FutureBuilder<
                                          List<Map<String, dynamic>>
                                        >(
                                          future: _firebaseService.fetchParts(
                                            product.id,
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              );
                                            }
                                            if (snapshot.hasError) {
                                              return Text(
                                                'エラー: ${snapshot.error}',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              );
                                            }
                                            if (!snapshot.hasData) {
                                              return const SizedBox.shrink();
                                            }
                                            final parts = snapshot.data!;
                                            if (parts.isEmpty) {
                                              return const Text(
                                                '部材なし',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            }
                                            // デバッグ用: 部材データ内容を表示
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ...parts.map((part) {
                                                  return Text(
                                                    '${part['partName']}（${part['floor']}）',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  );
                                                }).toList(),
                                                Text(
                                                  '部材データ: ' + parts.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              }).toList(),
                            ],
                          ),
                      ];
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 工種別ガントチャートビュー
  Widget _buildWorkTypeGanttView() {
    final workTypeState = Provider.of<WorkTypeState>(context);
    final processList = workTypeState.processList;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProcessStepSelector(
          onProcessChanged: (String process) {
            workTypeState.setCategory(process);
            workTypeState.setProcess(process);
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<WorkTypeGanttData>>(
            stream: _firebaseService.getWorkTypeGanttStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('エラー: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('工種別ガントチャート用データがありません'));
              }
              final selectedCategory = workTypeState.selectedCategory;
              final filteredData = selectedCategory.isNotEmpty
                  ? snapshot.data!
                        .where((d) => d.type == selectedCategory)
                        .toList()
                  : snapshot.data!;
              return WorkTypeGanttWidget(
                workTypeData: filteredData,
                processList: processList,
                startDate: startDate,
                endDate: endDate,
              );
            },
          ),
        ),
      ],
    );
  }

  // ガントチャート（旧メソッド - 後方互換性のため残す）
  Widget _buildGanttChart() {
    if (_currentGanttType == GanttType.product) {
      return _buildProductGanttView();
    } else {
      return _buildWorkTypeGanttView();
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

  Future<List<Map<String, dynamic>>> fetchParts(String productId) async {
    final snapshot = await _firebaseService.getPartsSnapshot(productId);
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
