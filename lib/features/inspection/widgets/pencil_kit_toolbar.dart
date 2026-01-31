import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 条件付きインポート: Web ではスタブを、ネイティブでは実際の pencil_kit を使用
import 'pencil_kit_stub.dart'
    if (dart.library.io) 'pencil_kit_native.dart';

import '../application/pencil_kit_providers.dart';

/// PencilKit ツールバーウィジェット
/// 
/// Apple 純正風のミニマルなデザインで、以下の機能を提供:
/// - ツールパレット表示/非表示
/// - 元に戻す/やり直し
/// - 描画モード切り替え（指/Apple Pencil）
/// - クリア
class PencilKitToolbar extends ConsumerWidget {
  const PencilKitToolbar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(pencilKitControllerProvider);
    final isToolPickerVisible = ref.watch(isToolPickerVisibleProvider);
    final drawingMode = ref.watch(drawingModeProvider);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ツールパレット表示/非表示
          _ToolbarButton(
            icon: isToolPickerVisible
                ? CupertinoIcons.paintbrush_fill
                : CupertinoIcons.paintbrush,
            label: 'パレット',
            isActive: isToolPickerVisible,
            onPressed: controller == null
                ? null
                : () {
                    if (isToolPickerVisible) {
                      controller.hide();
                    } else {
                      controller.show();
                    }
                    ref.read(isToolPickerVisibleProvider.notifier).state =
                        !isToolPickerVisible;
                  },
          ),
          // 元に戻す
          _ToolbarButton(
            icon: CupertinoIcons.arrow_uturn_left,
            label: '戻す',
            onPressed: controller == null ? null : () => controller.undo(),
          ),
          // やり直し
          _ToolbarButton(
            icon: CupertinoIcons.arrow_uturn_right,
            label: 'やり直し',
            onPressed: controller == null ? null : () => controller.redo(),
          ),
          // 描画モード切り替え
          _ToolbarButton(
            icon: drawingMode == DrawingMode.pencilOnly
                ? CupertinoIcons.pencil
                : CupertinoIcons.hand_raised_fill,
            label: drawingMode == DrawingMode.pencilOnly ? 'Pencil' : '指',
            isActive: drawingMode == DrawingMode.fingerDrawing,
            onPressed: () {
              final newMode = drawingMode == DrawingMode.pencilOnly
                  ? DrawingMode.fingerDrawing
                  : DrawingMode.pencilOnly;
              ref.read(drawingModeProvider.notifier).state = newMode;
            },
          ),
          // クリア
          _ToolbarButton(
            icon: CupertinoIcons.trash,
            label: 'クリア',
            isDestructive: true,
            onPressed: controller == null
                ? null
                : () => _showClearConfirmation(context, controller),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(
      BuildContext context, PencilKitController controller) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('描画をクリア'),
        content: const Text('すべての手書きを消去しますか？'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('キャンセル'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('クリア'),
            onPressed: () {
              controller.clear();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// ツールバーボタンウィジェット
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isActive = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color iconColor;
    if (onPressed == null) {
      iconColor = Colors.grey[400]!;
    } else if (isDestructive) {
      iconColor = CupertinoColors.destructiveRed;
    } else if (isActive) {
      iconColor = const Color(0xFF007AFF);
    } else {
      iconColor = Colors.grey[700]!;
    }

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: iconColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
