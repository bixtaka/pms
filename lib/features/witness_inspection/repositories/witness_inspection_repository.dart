import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/witness_inspection_model.dart';

final witnessInspectionRepositoryProvider = Provider<WitnessInspectionRepository>((ref) {
  return WitnessInspectionRepository();
});

class WitnessInspectionRepository {
  Future<List<ProductData>> getMockProducts() async {
    // 擬似的なネットワーク遅延
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 10件程度のダミーデータを返す
    return [
      const ProductData(id: '1', section: '1節', category: '柱', productCode: 'C1'),
      const ProductData(id: '2', section: '1節', category: '柱', productCode: 'C2'),
      const ProductData(id: '3', section: '1節', category: '柱', productCode: 'C3'),
      const ProductData(id: '4', section: '1節', category: '梁', productCode: 'G1'),
      const ProductData(id: '5', section: '1節', category: '梁', productCode: 'G2'),
      const ProductData(id: '6', section: '1節', category: '梁', productCode: 'G3'),
      const ProductData(id: '7', section: '2節', category: '柱', productCode: 'C4'),
      const ProductData(id: '8', section: '2節', category: '柱', productCode: 'C5'),
      const ProductData(id: '9', section: '2節', category: '梁', productCode: 'G4'),
      const ProductData(id: '10', section: '2節', category: '梁', productCode: 'G5'),
    ];
  }
}

// モックデータを取得するためのFutureProvider
final mockProductsProvider = FutureProvider<List<ProductData>>((ref) async {
  final repository = ref.read(witnessInspectionRepositoryProvider);
  return repository.getMockProducts();
});
