import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/product_providers.dart';
import '../../../models/product.dart';
import '../../process_progress/presentation/process_progress_screen.dart';

/// 製品一覧画面
class ProductListScreen extends ConsumerWidget {
  final String projectId;
  final String projectName;
  const ProductListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByProjectProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: Text('$projectName の製品一覧')),
      body: productsAsync.when(
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (_, i) => _ProductTile(
            projectId: projectId,
            product: products[i],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
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
      title:
          Text(product.productCode.isNotEmpty ? product.productCode : product.name),
      subtitle: Text(
          '${product.memberType.isNotEmpty ? product.memberType : product.type} / ${product.overallStatus}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProcessProgressScreen(
              projectId: projectId,
              productId: product.id,
            ),
          ),
        );
      },
    );
  }
}
