/// 工程マスタ
class ProcessMaster {
  final String id;
  final String name;
  final String memberType;
  final String stage;
  final int orderInStage;
  final bool isInspection;

  const ProcessMaster({
    required this.id,
    required this.name,
    required this.memberType,
    required this.stage,
    required this.orderInStage,
    required this.isInspection,
  });

  ProcessMaster copyWith({
    String? id,
    String? name,
    String? memberType,
    String? stage,
    int? orderInStage,
    bool? isInspection,
  }) =>
      ProcessMaster(
        id: id ?? this.id,
        name: name ?? this.name,
        memberType: memberType ?? this.memberType,
        stage: stage ?? this.stage,
        orderInStage: orderInStage ?? this.orderInStage,
        isInspection: isInspection ?? this.isInspection,
      );

  factory ProcessMaster.fromJson(Map<String, dynamic> json, String id) =>
      ProcessMaster(
        id: id,
        name: json['name'] ?? '',
        memberType: json['memberType'] ?? '',
        stage: json['stage'] ?? '',
        orderInStage: (json['orderInStage'] ?? 0) as int,
        isInspection: json['isInspection'] ?? false,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'memberType': memberType,
    'stage': stage,
    'orderInStage': orderInStage,
    'isInspection': isInspection,
  };
}
