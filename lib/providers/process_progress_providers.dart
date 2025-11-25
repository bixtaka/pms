import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/process_progress/data/process_progress_repository.dart';
import '../features/process_progress/data/process_master_repository.dart';
import '../features/products/data/product_repository.dart';
import '../models/product.dart';
import '../models/process_master.dart';
import '../models/process_progress.dart';

// Repository providers
final processProgressRepoProvider = Provider<ProcessProgressRepository>((ref) {
  return ProcessProgressRepository();
});
final processMasterRepoProvider = Provider<ProcessMasterRepository>((ref) {
  return ProcessMasterRepository();
});
final productRepoProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// Product 単体
final productProvider =
    StreamProvider.family<Product, ({String projectId, String productId})>(
  (ref, params) {
    final repo = ref.watch(productRepoProvider);
    return repo.streamOne(params.projectId, params.productId);
  },
);

// ProcessMaster 一覧
final processMastersByMemberTypeProvider =
    StreamProvider.family<List<ProcessMaster>, String>((ref, memberType) {
  final repo = ref.watch(processMasterRepoProvider);
  return repo.streamByMemberType(memberType);
});

// ProcessProgress 一覧
final processProgressByProductProvider = StreamProvider.family<
    List<ProcessProgress>, ({String projectId, String productId})>((ref, p) {
  final repo = ref.watch(processProgressRepoProvider);
  return repo.streamAll(p.projectId, p.productId);
});
