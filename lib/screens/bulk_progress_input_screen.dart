import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/product.dart';

class BulkProgressInputScreen extends StatefulWidget {
  const BulkProgressInputScreen({super.key});

  @override
  State<BulkProgressInputScreen> createState() =>
      _BulkProgressInputScreenState();
}

class _BulkProgressInputScreenState extends State<BulkProgressInputScreen> {
  String? selectedProductId;
  final FirebaseService _firebaseService = FirebaseService();

  // 一括選択用チェックボックスの状態管理
  final Set<String> selectedProductIds = {};

  // 追加の状態変数
  DateTime selectedDate = DateTime.now();
  String selectedPerson = '';
  String selectedCategory = '一次加工';
  String selectedProcess = '';
  String selectedStatus = 'not_started';

  // 担当者リスト（サンプル）
  final List<String> personList = ['田中太郎', '佐藤花子', '鈴木一郎', '高橋美咲'];

  // 工種リスト（サンプル）
  final List<String> processListDefault = ['コア組立', 'コア溶接', '仕口組立', '仕口溶接'];
  final List<String> processListIchiji = ['孔あけ', '切断', '開先加工', 'ショットブラスト'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('進捗状況一括入力'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '製品一括入力',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // --- ここからアコーディオンUI ---
            ExpansionTile(
              title: const Text(
                '進捗一括入力',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日付
                      const Text(
                        '日付',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null && picked != selectedDate) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 担当者
                      const Text(
                        '担当者',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: selectedPerson.isEmpty ? null : selectedPerson,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text('担当者を選択'),
                        items: const [
                          DropdownMenuItem(value: '田中', child: Text('田中')),
                          DropdownMenuItem(value: '佐藤', child: Text('佐藤')),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPerson = newValue ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // 分類
                      const Text(
                        '分類',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: '一次加工', child: Text('一次加工')),
                          DropdownMenuItem(value: '柱', child: Text('柱')),
                          DropdownMenuItem(value: '梁・間柱', child: Text('梁・間柱')),
                          DropdownMenuItem(value: 'ブレース', child: Text('ブレース')),
                          DropdownMenuItem(value: '他', child: Text('他')),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCategory = newValue ?? '一次加工';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // 工種
                      const Text(
                        '工種',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: selectedProcess.isEmpty ? null : selectedProcess,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text('工種を選択'),
                        items:
                            (selectedCategory == '一次加工'
                                    ? processListIchiji
                                    : processListDefault)
                                .map((String process) {
                                  return DropdownMenuItem<String>(
                                    value: process,
                                    child: Text(process),
                                  );
                                })
                                .toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedProcess = newValue ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // 状態
                      const Text(
                        '状態',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'not_started',
                            child: Text('未着手'),
                          ),
                          DropdownMenuItem(
                            value: 'in_progress',
                            child: Text('作業中'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('完了'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedStatus = newValue ?? 'not_started';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- ここまでアコーディオンUI ---
            const SizedBox(height: 16),
            // 「ここに一括入力機能を実装します」の位置にボタンを移動
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 一括入力処理
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('一括入力が完了しました')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '一括入力実行',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 仮の入力フォーム
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '製品一括入力リスト',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 400, // 必要に応じて高さを調整
                      child: StreamBuilder<List<Product>>(
                        stream: _firebaseService.getProductsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('エラー: [${snapshot.error}]');
                          }
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          List<Product> products = snapshot.data!;
                          // 分類が「柱」の場合は柱のみ表示
                          if (selectedCategory == '柱') {
                            products = products
                                .where((p) => p.processCategory == '柱')
                                .toList();
                          }
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Table(
                                border: TableBorder.all(color: Colors.grey),
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                columnWidths: const {
                                  0: FixedColumnWidth(48), // チェックボックス
                                  1: FixedColumnWidth(150), // 製品名
                                  2: FixedColumnWidth(120), // 部材名
                                  3: FixedColumnWidth(100), // 材質
                                  4: FixedColumnWidth(80), // 工区
                                  5: FixedColumnWidth(60), // 節
                                  6: FixedColumnWidth(60), // 階
                                  7: FixedColumnWidth(120), // 状態
                                },
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                    children: [
                                      // チェックボックス（ヘッダー）
                                      const SizedBox.shrink(),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '製品名',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '部材名',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '材質',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '工区',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '節',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '階',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '状態',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ...products.map(
                                    (product) => TableRow(
                                      children: [
                                        // チェックボックス
                                        Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Checkbox(
                                            value: selectedProductIds.contains(
                                              product.id,
                                            ),
                                            onChanged: (checked) {
                                              setState(() {
                                                if (checked == true) {
                                                  selectedProductIds.add(
                                                    product.id,
                                                  );
                                                } else {
                                                  selectedProductIds.remove(
                                                    product.id,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(product.name), // 製品名
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            product.partName ?? '',
                                          ), // 部材名
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            product.material ?? '',
                                          ), // 材質
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(product.area ?? ''), // 工区
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(product.setsu ?? ''), // 節
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(product.floor ?? ''), // 階
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: DropdownButton<String>(
                                            value: product.status,
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'not_started',
                                                child: Text('未着手'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'in_progress',
                                                child: Text('作業中'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'completed',
                                                child: Text('完了'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                _firebaseService
                                                    .updateProductStatus(
                                                      product.id,
                                                      value,
                                                    );
                                                setState(() {});
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
