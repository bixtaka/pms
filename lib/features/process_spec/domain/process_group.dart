/// SPEC 準拠: process_groups ドメインモデル
class ProcessGroup {
  final String id;
  final String key; // 英語キー
  final String label; // 日本語ラベル
  final int sortOrder;

  const ProcessGroup({
    required this.id,
    required this.key,
    required this.label,
    required this.sortOrder,
  });
}
