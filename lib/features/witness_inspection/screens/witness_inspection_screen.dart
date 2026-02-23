import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/witness_inspection_model.dart';
import '../repositories/witness_inspection_repository.dart';

class WitnessInspectionScreen extends ConsumerStatefulWidget {
  const WitnessInspectionScreen({super.key});

  @override
  ConsumerState<WitnessInspectionScreen> createState() => _WitnessInspectionScreenState();
}

class _WitnessInspectionScreenState extends ConsumerState<WitnessInspectionScreen> {
  String _searchQuery = '';
  String? _selectedSection;
  String? _selectedCategory;
  ProductData? _selectedProduct;
  String? _selectedMeasurementPoint;

  final List<String> _measurementPoints = ['寸法', '溶接', '外観'];

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(mockProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('立会検査写真'),
      ),
      body: Column(
        children: [
          // 上部：検索・絞り込みエリア
          _buildFilterArea(),
          const Divider(height: 1),
          // 中央：製品リストエリア
          Expanded(
            child: _buildProductList(productsAsync),
          ),
          // 下部：撮影コントロールエリア
          if (_selectedProduct != null) _buildShootingControlArea(),
        ],
      ),
    );
  }

  Widget _buildFilterArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: '製品符号で検索',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _selectedProduct = null;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '節',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSection,
                  items: ['すべて', '1節', '2節'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value == 'すべて' ? null : value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSection = value;
                      _selectedProduct = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '種別',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
                  items: ['すべて', '柱', '梁'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value == 'すべて' ? null : value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _selectedProduct = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(AsyncValue<List<ProductData>> productsAsync) {
    return productsAsync.when(
      data: (products) {
        // フィルタリング処理
        final filteredProducts = products.where((p) {
          final matchQuery = p.productCode.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchSection = _selectedSection == null || p.section == _selectedSection;
          final matchCategory = _selectedCategory == null || p.category == _selectedCategory;
          return matchQuery && matchSection && matchCategory;
        }).toList();

        if (filteredProducts.isEmpty) {
          return const Center(child: Text('該当する製品がありません'));
        }

        return ListView.builder(
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            final isSelected = _selectedProduct?.id == product.id;

            return ListTile(
              title: Text(product.productCode),
              subtitle: Text('${product.section} / ${product.category}'),
              selected: isSelected,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              onTap: () {
                setState(() {
                  _selectedProduct = product;
                  _selectedMeasurementPoint = null; // 製品変更時に測定箇所をリセット
                });
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
    );
  }

  Widget _buildShootingControlArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_selectedProduct!.section} / ${_selectedProduct!.category} / ${_selectedProduct!.productCode}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.center,
              children: _measurementPoints.map((point) {
                return ChoiceChip(
                  label: Text(point),
                  selected: _selectedMeasurementPoint == point,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMeasurementPoint = selected ? point : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectedMeasurementPoint == null
                  ? null
                  : () {
                      // 撮影ボタン押下処理
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$_selectedMeasurementPointのカメラを起動します'),
                        ),
                      );
                    },
              icon: const Icon(Icons.camera_alt),
              label: const Text('撮影する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
