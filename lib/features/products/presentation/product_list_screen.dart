import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/product_providers.dart';
import '../../../models/product.dart';
import '../../process_progress/presentation/process_progress_screen.dart';
import '../application/product_filter_state.dart';
import '../application/product_filter_notifier.dart';

/// 製品一覧画面（フィルタ付き）
class ProductListScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  const ProductListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late final TextEditingController _storyCtrl;
  late final TextEditingController _gridCtrl;
  late final TextEditingController _keywordCtrl;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(productFilterProvider);
    _storyCtrl = TextEditingController(
      text: filter.selectedBlocks.isNotEmpty ? filter.selectedBlocks.first : '',
    );
    _gridCtrl = TextEditingController(
      text: filter.selectedSegments.isNotEmpty ? filter.selectedSegments.first : '',
    );
    _keywordCtrl = TextEditingController(text: filter.keyword);
  }

  @override
  void dispose() {
    _storyCtrl.dispose();
    _gridCtrl.dispose();
    _keywordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsByProjectProvider(widget.projectId));
    final filteredProducts =
        ref.watch(filteredProductsProvider(widget.projectId));
    final filter = ref.watch(productFilterProvider);
    final notifier = ref.read(productFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.projectName} の製品一覧')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (_) => Column(
          children: [
            _ProductFilterPanel(
              filter: filter,
              storyCtrl: _storyCtrl,
              gridCtrl: _gridCtrl,
              keywordCtrl: _keywordCtrl,
              notifier: notifier,
              onClear: () {
                notifier.clearAll();
                _storyCtrl.text = '';
                _gridCtrl.text = '';
                _keywordCtrl.text = '';
              },
            ),
            const Divider(height: 0),
            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (_, i) => _ProductTile(
                  projectId: widget.projectId,
                  product: filteredProducts[i],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// フィルタ UI パネル
class _ProductFilterPanel extends StatelessWidget {
  final ProductFilterState filter;
  final TextEditingController storyCtrl;
  final TextEditingController gridCtrl;
  final TextEditingController keywordCtrl;
  final ProductFilterNotifier notifier;
  final VoidCallback onClear;

  const _ProductFilterPanel({
    required this.filter,
    required this.storyCtrl,
    required this.gridCtrl,
    required this.keywordCtrl,
    required this.notifier,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('検索・フィルタ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: '部材種別'),
                    value: filter.selectedMemberTypes.isNotEmpty
                        ? filter.selectedMemberTypes.first
                        : '',
                    items: const [
                      DropdownMenuItem(value: '', child: Text('指定なし')),
                      DropdownMenuItem(value: 'COLUMN', child: Text('COLUMN')),
                      DropdownMenuItem(value: 'GIRDER', child: Text('GIRDER')),
                      DropdownMenuItem(value: 'BEAM', child: Text('BEAM')),
                      DropdownMenuItem(
                          value: 'INTERMEDIATE', child: Text('INTERMEDIATE')),
                    ],
                    onChanged: (v) => notifier.setMemberType(
                      (v != null && v.isNotEmpty) ? v : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'ステータス'),
                    value: filter.status ?? '',
                    items: const [
                      DropdownMenuItem(value: '', child: Text('指定なし')),
                      DropdownMenuItem(
                          value: 'not_started', child: Text('not_started')),
                      DropdownMenuItem(
                          value: 'in_progress', child: Text('in_progress')),
                      DropdownMenuItem(
                          value: 'completed', child: Text('completed')),
                      DropdownMenuItem(value: 'partial', child: Text('partial')),
                    ],
                    onChanged: (v) => notifier.setStatus(
                      (v != null && v.isNotEmpty) ? v : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: storyCtrl,
                    decoration:
                        const InputDecoration(labelText: '節/階 (1C,2C,2G etc)'),
                    onChanged: notifier.setStoryOrSet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: gridCtrl,
                    decoration: const InputDecoration(labelText: '通り芯 (X1Y1 etc)'),
                    onChanged: notifier.setGrid,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: keywordCtrl,
              decoration: const InputDecoration(
                labelText: 'キーワード（製品符号・名称・備考）',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: notifier.setKeyword,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear),
                label: const Text('クリア'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final String projectId;
  final Product product;
  const _ProductTile({required this.projectId, required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        product.productCode.isNotEmpty ? product.productCode : product.name,
      ),
      subtitle: Text(
        '${product.memberType.isNotEmpty ? product.memberType : product.type} / ${product.overallStatus}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProcessProgressScreen(
              projectId: projectId,
              productId: product.id,
              productCode: product.productCode,
            ),
          ),
        );
      },
    );
  }
}
