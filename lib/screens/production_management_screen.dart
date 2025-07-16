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
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:convert'; // 追加

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
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['csv'],
                          );
                      if (result != null) {
                        String csvString;
                        if (result.files.single.bytes != null) {
                          // Webの場合
                          csvString = utf8.decode(result.files.single.bytes!);
                        } else if (result.files.single.path != null) {
                          // モバイル/デスクトップの場合
                          final file = File(result.files.single.path!);
                          csvString = await file.readAsString();
                        } else {
                          throw Exception('ファイルが読み込めませんでした');
                        }
                        final csvTable = CsvToListConverter(
                          eol: '\n',
                        ).convert(csvString);
                        // 1行目はヘッダー
                        for (int i = 1; i < csvTable.length; i++) {
                          final row = csvTable[i];
                          if (row.length < 7) continue;
                          final area = row[0]?.toString() ?? '';
                          final type = row[1]?.toString() ?? '';
                          final name = row[2]?.toString() ?? '';
                          final size = row[3]?.toString() ?? '';
                          final length =
                              int.tryParse(row[4]?.toString() ?? '') ?? 0;
                          final quantity =
                              int.tryParse(row[5]?.toString() ?? '') ?? 0;
                          final totalWeight =
                              double.tryParse(row[6]?.toString() ?? '') ?? 0.0;
                          // Firestoreに保存
                          await _firebaseService.addOrUpdateProductFromCsv(
                            id: name,
                            name: name,
                            type: type,
                            area: area,
                            size: size,
                            length: length,
                            quantity: quantity,
                            totalWeight: totalWeight,
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CSV取り込みが完了しました')),
                        );
                        setState(() {}); // リスト即時反映
                      }
                    } catch (e) {
                      print('CSV取込エラー: $e');
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('CSV取込エラー: $e')));
                    } finally {
                      setState(() => _isAddingSample = false);
                    }
                  },
            icon: const Icon(Icons.upload_file, color: Colors.white),
            label: const Text('CSV取り込み', style: TextStyle(color: Colors.white)),
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
      body: FutureBuilder<Map<String, Map<String, Map<String, dynamic>>>>(
        future: _fetchAllProgressData(),
        builder: (context, progressSnapshot) {
          if (progressSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                // カテゴリ切り替えチップは製品別タブのときだけ表示
                if (_currentGanttType == GanttType.product)
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('一次加工'),
                        selected: selectedCategory == '一次加工',
                        onSelected: (_) {
                          setState(() => selectedCategory = '一次加工');
                          Provider.of<WorkTypeState>(
                            context,
                            listen: false,
                          ).setCategory('一次加工');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('柱'),
                        selected: selectedCategory == '柱',
                        onSelected: (_) {
                          setState(() => selectedCategory = '柱');
                          Provider.of<WorkTypeState>(
                            context,
                            listen: false,
                          ).setCategory('柱');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('梁・間柱'),
                        selected: selectedCategory == '梁・間柱',
                        onSelected: (_) {
                          setState(() => selectedCategory = '梁・間柱');
                          Provider.of<WorkTypeState>(
                            context,
                            listen: false,
                          ).setCategory('梁・間柱');
                        },
                      ),
                    ],
                  ),
                // タブの下の中身
                Expanded(
                  child: _currentGanttType == GanttType.product
                      ? (progressSnapshot.connectionState ==
                                ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : StreamBuilder<List<Product>>(
                                stream: _firebaseService.getProductsStream(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('エラー:  {snapshot.error}'),
                                    );
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Center(
                                      child: Text('製品データがありません'),
                                    );
                                  }
                                  final products = snapshot.data!;
                                  final allProgress =
                                      progressSnapshot.data ?? {};
                                  return _buildProductGanttView(
                                    products,
                                    allProgress,
                                  );
                                },
                              ))
                      : _buildWorkTypeGanttView(),
                ),
              ],
            ),
          );
        },
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

  // 製品別ガントチャートビュー
  Widget _buildProductGanttView(
    List<Product> products,
    Map<String, Map<String, Map<String, dynamic>>> allProgress,
  ) {
    final workTypeState = Provider.of<WorkTypeState>(context);
    final processNames = workTypeState.processList
        .where((p) => p.isNotEmpty)
        .toList();
    final selectedCategory = workTypeState.selectedCategory;
    // カテゴリごとにヘッダー工程名リストを切り替え
    // List<String> processNames; // この行は削除
    // if (selectedCategory == '一次加工') { // この行は削除
    //   processNames = ['孔あけ', '切断', '開先加工', 'ショットブラスト']; // この行は削除
    // } else if (selectedCategory == '梁・間柱') { // この行は削除
    //   processNames = ['組立', '検品', '溶接', '寸法', 'ＵＴ', '塗装', '積込']; // この行は削除
    // } else { // この行は削除
    //   processNames = [ // この行は削除
    //     'コア組立', // この行は削除
    //     'コア溶接', // この行は削除
    //     'コアＵＴ', // この行は削除
    //     '仕口組立', // この行は削除
    //     '仕口検品', // この行は削除
    //     '仕口溶接', // この行は削除
    //     '仕口仕上げ', // この行は削除
    //     '仕口ＵＴ', // この行は削除
    //     '柱組立', // この行は削除
    //     '柱溶接', // この行は削除
    //     '柱仕上げ', // この行は削除
    //     '柱ＵＴ', // この行は削除
    //     '二次部材組立', // この行は削除
    //     '二次部材検品', // この行は削除
    //     '二次部材溶接', // この行は削除
    //     '仕上げ', // この行は削除
    //     '柱ＵＴ', // この行は削除
    //     '第三者ＵＴ', // この行は削除
    //     '塗装', // この行は削除
    //     '積込', // この行は削除
    //   ]; // この行は削除
    // } // この行は削除
    // カテゴリに応じて製品を絞り込み
    List<Product> filteredProducts;
    if (selectedCategory == '柱') {
      filteredProducts = products.where((p) => p.type == '本柱').toList();
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
      (a, b) =>
          isAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
    );

    // ラベル行＋データ行を横スクロールでラップし、データ行は高さ指定＋ListViewで描画
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // ヘッダー
          Row(
            children: [
              Container(
                width: 120,
                padding: const EdgeInsets.all(8.0),
                child: const Text(
                  '製品符号',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...processNames.map(
                (p) => Container(
                  width: 80,
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    p,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          // データ行（高さを指定してListView.builderで描画）
          Container(
            height: MediaQuery.of(context).size.height - 250,
            width: 120.0 + 80.0 * processNames.length, // ヘッダーと同じ幅を指定
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final productProgress = allProgress[product.id] ?? {};
                return Row(
                  children: [
                    Container(
                      width: 120,
                      padding: const EdgeInsets.all(8.0),
                      child: Text(product.name),
                    ),
                    ...processNames.map((processName) {
                      final data = productProgress[processName];
                      Color bgColor;
                      if (data == null) {
                        bgColor = Colors.grey.shade100;
                      } else {
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
                      }
                      String dateStr = '';
                      String person = '';
                      if (data != null) {
                        if (data['date'] != null) {
                          final date = (data['date'] as Timestamp).toDate();
                          dateStr =
                              '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
                        }
                        person = data['person'] ?? '';
                      }
                      return Container(
                        width: 80,
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(dateStr),
                            const SizedBox(width: 4),
                            Text(person),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
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
  Widget _buildGanttChart(
    List<Product> products,
    Map<String, Map<String, Map<String, dynamic>>> allProgress,
  ) {
    if (_currentGanttType == GanttType.product) {
      return _buildProductGanttView(products, allProgress);
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

  // 全製品の進捗データを一括取得
  Future<Map<String, Map<String, Map<String, dynamic>>>>
  _fetchAllProgressData() async {
    final products = await _firebaseService.getProductsStream().first;
    final Map<String, Map<String, Map<String, dynamic>>> allProgress = {};
    // 並列で取得
    await Future.wait(
      products.map((product) async {
        final progress = await _firebaseService.getAllProductProgress(
          product.id,
        );
        allProgress[product.id] = progress;
      }),
    );
    return allProgress;
  }
}
