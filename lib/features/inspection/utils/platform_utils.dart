import 'package:flutter/foundation.dart';

/// プラットフォーム判定ユーティリティ
/// 
/// Web 環境と Native 環境の両方で安全に動作する
/// プラットフォーム検出を提供します。
/// 
/// dart:io の Platform を使用せず、flutter/foundation.dart の
/// defaultTargetPlatform と kIsWeb を使用することで、
/// Web 環境でのランタイムエラーを防ぎます。
class PlatformUtils {
  PlatformUtils._();

  /// 現在のプラットフォームが iOS かどうかを判定
  /// 
  /// Web 環境では常に false を返す
  static bool get isIOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// 現在のプラットフォームが Android かどうかを判定
  static bool get isAndroid {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// 現在のプラットフォームが Web かどうかを判定
  static bool get isWeb => kIsWeb;

  /// 現在のプラットフォームがデスクトップ（Windows/macOS/Linux）かどうかを判定
  static bool get isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.linux;
  }

  /// 現在のプラットフォームが macOS かどうかを判定
  static bool get isMacOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// 現在のプラットフォームが Windows かどうかを判定
  static bool get isWindows {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  /// 現在のプラットフォームが Linux かどうかを判定
  static bool get isLinux {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.linux;
  }

  /// PencilKit がサポートされているかどうかを判定
  /// iOS 13.0 以上でのみサポート（実機/シミュレータ）
  static bool get isPencilKitSupported => isIOS;

  /// 現在のプラットフォーム名を取得
  static String get platformName {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }
}
