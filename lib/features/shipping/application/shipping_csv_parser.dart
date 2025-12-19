import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../domain/shipping_row.dart';

class ShippingCsvParser {
  const ShippingCsvParser();

  List<ShippingRow> parse(
    String csvContent, {
    bool logPreview = false,
  }) {
    final normalizedContent =
        csvContent.startsWith('\ufeff') ? csvContent.substring(1) : csvContent;
    final converter = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    );
    final rows = converter.convert(normalizedContent);
    if (rows.isEmpty) return const <ShippingRow>[];

    final headerCells = rows.first.map((e) => e.toString().trim()).toList();
    _ensureRequiredHeaders(headerCells);
    final headerIndex = _buildHeaderIndex(headerCells);
    final missingHeaders = <String>[];
    if (!_hasAny(headerIndex, _koukuHeaders)) missingHeaders.add('工区');
    if (!_hasAny(headerIndex, _kindHeaders)) missingHeaders.add('種別');
    if (!_hasAny(headerIndex, _productCodeHeaders)) missingHeaders.add('製品符号');
    if (!_hasAny(headerIndex, _sectionHeaders)) missingHeaders.add('寸法');
    if (!_hasAny(headerIndex, _lengthHeaders)) missingHeaders.add('長さ(㎜)');
    if (missingHeaders.isNotEmpty) {
      debugPrint('[ShippingCsvParser] Missing columns: ${missingHeaders.join(', ')}');
    }

    final result = <ShippingRow>[];
    for (final row in rows.skip(1)) {
      if (_isRowEmpty(row)) continue;

      final kouku = _valueFor(row, headerIndex, _koukuHeaders);
      final kind = _valueFor(row, headerIndex, _kindHeaders);
      final productCode = _valueFor(row, headerIndex, _productCodeHeaders);
      final sectionSize = _valueFor(row, headerIndex, _sectionHeaders);
      final lengthRaw = _valueFor(row, headerIndex, _lengthHeaders);
      final lengthMm = _parseLength(lengthRaw);
      final floor = _extractFloor(kind, productCode);
      final setsu = _extractSetsu(kind, productCode);
      if (productCode.isEmpty) continue;

      result.add(
        ShippingRow(
          kouku: kouku,
          kind: kind,
          productCode: productCode,
          sectionSize: sectionSize,
          lengthMm: lengthMm,
          floor: floor,
          setsu: setsu,
        ),
      );
    }

    if (logPreview && result.isNotEmpty) {
      final koukus = <String>{for (final r in result) r.kouku.trim()}.toList()..sort();
      final koukuPreview = koukus.take(12).join(',');
      debugPrint(
          '[ShippingCsvParser] Parsed ${result.length} rows, koukus=${koukus.length} [$koukuPreview]');
      for (final row in result.take(20)) {
        debugPrint(
          '[ShippingCsvParser] kouku=${row.kouku}, kind=${row.kind}, code=${row.productCode}, floor=${row.floor}, setsu=${row.setsu}, section=${row.sectionSize}, lengthMm=${row.lengthMm}',
        );
      }
    }

    return result;
  }
}

const _koukuHeaders = ['工区'];
const _kindHeaders = ['種別'];
const _productCodeHeaders = ['製品符号', '製品コード'];
const _sectionHeaders = ['寸法', '断面', '断面寸法'];
const _lengthHeaders = ['長さ(㎜)', '長さ(mm)', '長さ'];
const _strictHeaders = ['工区', '種別', '製品符号', '断面寸法', '長さ'];

void _ensureRequiredHeaders(List<String> headers) {
  final normalizedHeaders = headers.map(_normalizeHeader).toList();
  final missing = _strictHeaders
      .map(_normalizeHeader)
      .where((h) => !normalizedHeaders.contains(h))
      .toList();
  if (missing.isNotEmpty) {
    throw FormatException(
      'CSV列名が一致しません。期待: ${_strictHeaders.join(', ')}',
    );
  }
}

Map<String, int> _buildHeaderIndex(List<String> headers) {
  final map = <String, int>{};
  for (var i = 0; i < headers.length; i++) {
    final normalized = _normalizeHeader(headers[i]);
    if (normalized.isEmpty) continue;
    map.putIfAbsent(normalized, () => i);
  }
  return map;
}

String _normalizeHeader(String value) {
  final compacted = value.replaceAll(RegExp(r'[ \t\u3000]'), '');
  return compacted.toLowerCase();
}

String _valueFor(
  List<dynamic> row,
  Map<String, int> headerIndex,
  List<String> candidates,
) {
  for (final candidate in candidates) {
    final normalized = _normalizeHeader(candidate);
    final index = headerIndex[normalized];
    if (index != null && index < row.length) {
      return row[index].toString().trim();
    }
  }
  return '';
}

bool _isRowEmpty(List<dynamic> row) {
  return row.every((cell) => cell.toString().trim().isEmpty);
}

bool _hasAny(Map<String, int> headerIndex, List<String> candidates) {
  return candidates
      .map(_normalizeHeader)
      .any((candidate) => headerIndex.containsKey(candidate));
}

int _parseLength(String raw) {
  if (raw.trim().isEmpty) return 0;
  final cleaned = raw.replaceAll(RegExp(r'[^0-9-]'), '');
  if (cleaned.isEmpty) return 0;
  return int.tryParse(cleaned) ?? 0;
}

String? _extractSetsu(String kind, String productCode) {
  if (kind.trim() != '柱') return null;
  final code = productCode.trim();
  final hyphenMatch = RegExp(r'^(\d+C)-', caseSensitive: false).firstMatch(code);
  if (hyphenMatch != null) return hyphenMatch.group(1);
  final fallbackMatch = RegExp(r'^(\d+C)', caseSensitive: false).firstMatch(code);
  return fallbackMatch?.group(1);
}

int? _extractFloor(String kind, String productCode) {
  final trimmedKind = kind.trim();
  final code = productCode.trim();
  RegExp? pattern;
  switch (trimmedKind) {
    case '大梁':
      pattern = RegExp(r'(\d+)G', caseSensitive: false);
      break;
    case '小梁':
      pattern = RegExp(r'(\d+)[Bb]');
      break;
    case '間柱':
      pattern = RegExp(r'(\d+)[Pp]');
      break;
    default:
      pattern = null;
  }
  if (pattern == null) return null;
  final match = pattern.firstMatch(code);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}
