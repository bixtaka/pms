/// SPEC 準拠: process_steps ドメインモデル
class ProcessStep {
  final String id;
  final String groupId;
  final String key; // 英語キー
  final String label; // 日本語ラベル
  final int sortOrder;

  const ProcessStep({
    required this.id,
    required this.groupId,
    required this.key,
    required this.label,
    required this.sortOrder,
  });
}
