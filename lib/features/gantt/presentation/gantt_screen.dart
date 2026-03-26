import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../features/projects/domain/project.dart';
import '../../../features/products/domain/product.dart';
import '../../products/data/product_repository.dart';
import '../../../features/products/application/product_providers.dart';
import '../../shipping/application/shipping_table_notifier.dart';
import '../../shipping/domain/shipping_row.dart';
import '../../process_spec/domain/process_group.dart';
import '../../process_spec/domain/process_step.dart';
import '../../process_spec/presentation/process_colors.dart';
import '../application/gantt_providers.dart';
import '../application/product_gantt_progress_service.dart';
import '../../products/application/product_inspection_providers.dart';
import '../../process_spec/data/process_progress_save_service.dart';
import '../../process_spec/data/process_progress_daily_repository.dart';
import '../../process_spec/domain/process_progress_daily.dart';
import '../application/gantt_shared_providers.dart' show selectedProjectIdProvider;

import '../../inspection/inspection_pencil_kit.dart';
import '../../products/presentation/widgets/product_drawing_thumbnail.dart';




// 抽出したモジュールのインポート
import '../domain/gantt_models.dart';

part 'inspection/inspection_filter_state.dart';
part 'inspection/product_result_input_page.dart';
part 'inspection/_inline_status_strip2.dart';


