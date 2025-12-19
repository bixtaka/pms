import 'package:flutter/foundation.dart';

@immutable
class ShippingRow {
  final String kouku;
  final String kind;
  final String productCode;
  final String sectionSize;
  final int lengthMm;
  final int? floor;
  final String? setsu;

  const ShippingRow({
    required this.kouku,
    required this.kind,
    required this.productCode,
    required this.sectionSize,
    required this.lengthMm,
    this.floor,
    this.setsu,
  });

  ShippingRow copyWith({
    String? kouku,
    String? kind,
    String? productCode,
    String? sectionSize,
    int? lengthMm,
    int? floor,
    String? setsu,
  }) {
    return ShippingRow(
      kouku: kouku ?? this.kouku,
      kind: kind ?? this.kind,
      productCode: productCode ?? this.productCode,
      sectionSize: sectionSize ?? this.sectionSize,
      lengthMm: lengthMm ?? this.lengthMm,
      floor: floor ?? this.floor,
      setsu: setsu ?? this.setsu,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShippingRow &&
        other.kouku == kouku &&
        other.kind == kind &&
        other.productCode == productCode &&
        other.sectionSize == sectionSize &&
        other.lengthMm == lengthMm &&
        other.floor == floor &&
        other.setsu == setsu;
  }

  @override
  int get hashCode => Object.hash(
        kouku,
        kind,
        productCode,
        sectionSize,
        lengthMm,
        floor,
        setsu,
      );
}
