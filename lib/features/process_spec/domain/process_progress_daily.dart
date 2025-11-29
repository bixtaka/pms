/// SPEC 準拠: process_progress_daily ドメインモデル
class ProcessProgressDaily {
  final String id;
  final String productId;
  final String stepId;
  final DateTime date;
  final int doneQty;
  final String note;

  const ProcessProgressDaily({
    required this.id,
    required this.productId,
    required this.stepId,
    required this.date,
    required this.doneQty,
    required this.note,
  });
}
