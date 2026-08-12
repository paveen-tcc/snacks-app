import '../../core/formatters/rupees.dart';

class BulkSnackParseException extends FormatException {
  BulkSnackParseException(this.rowNumber, String detail)
    : super('Row $rowNumber: $detail');

  final int rowNumber;
}

enum _BulkSnackLayout { legacy, priced }

const _legacyHeader = [
  'name',
  'category',
  'image_url',
  'veg_or_non_veg',
  'serving_size',
  'share_count',
  'is_active',
  'sort_order',
];

const _pricedHeader = [
  'name',
  'category',
  'image_url',
  'veg_or_non_veg',
  'serving_size',
  'share_count',
  'price_rupees',
  'is_active',
  'sort_order',
];

List<Map<String, dynamic>> parseBulkSnacks(String raw) {
  final lines = raw
      .split(RegExp(r'\r\n|\r|\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return const [];

  final delimiter = lines.any((line) => line.contains('\t'))
      ? '\t'
      : lines.any((line) => line.contains(';'))
      ? ';'
      : ',';
  final firstRow = _splitBulkRow(lines.first, delimiter);
  final hasHeader =
      firstRow.isNotEmpty && _headerToken(firstRow.first) == 'name';
  final layout = hasHeader
      ? _layoutFromHeader(firstRow)
      : _layoutFromColumnCount(firstRow.length, 1);
  final firstDataIndex = hasHeader ? 1 : 0;
  final expectedColumns = layout == _BulkSnackLayout.priced ? 9 : 8;
  final snacks = <Map<String, dynamic>>[];

  for (var index = firstDataIndex; index < lines.length; index++) {
    final rowNumber = index + 1;
    final columns = _splitBulkRow(lines[index], delimiter);
    if (columns.length != expectedColumns) {
      throw BulkSnackParseException(
        rowNumber,
        'unsupported bulk upload layout; expected $expectedColumns columns',
      );
    }

    final name = columns[0].trim();
    if (name.isEmpty) {
      throw BulkSnackParseException(rowNumber, 'name is required');
    }
    final shareCount = int.tryParse(columns[5].trim());
    final priceRupees = layout == _BulkSnackLayout.priced
        ? parseWholeRupees(columns[6])
        : 0;
    if (priceRupees == null) {
      throw BulkSnackParseException(
        rowNumber,
        'price must be a whole number greater than or equal to 0',
      );
    }
    final activeIndex = layout == _BulkSnackLayout.priced ? 7 : 6;
    final sortIndex = layout == _BulkSnackLayout.priced ? 8 : 7;
    final normalizedType = columns[3].trim().toLowerCase();
    final isVeg = !{
      'non-veg',
      'non veg',
      'nveg',
      'nonveg',
      'false',
      'no',
      '0',
    }.contains(normalizedType);
    final sortOrder = int.tryParse(columns[sortIndex].trim());

    snacks.add({
      'name': name,
      'category': columns[1].trim(),
      'emoji': columns[2].trim(),
      'isVeg': isVeg,
      'servingSize': columns[4].trim(),
      'shareCount': shareCount != null && shareCount > 0 ? shareCount : 1,
      'priceRupees': priceRupees,
      'isActive': _parseBoolToken(columns[activeIndex], defaultValue: true),
      'sortOrder': ?sortOrder,
    });
  }
  return snacks;
}

_BulkSnackLayout _layoutFromHeader(List<String> columns) {
  final normalized = columns.map(_headerToken).toList();
  if (_listEquals(normalized, _pricedHeader)) return _BulkSnackLayout.priced;
  if (_listEquals(normalized, _legacyHeader)) return _BulkSnackLayout.legacy;
  throw BulkSnackParseException(1, 'unsupported bulk upload header/layout');
}

_BulkSnackLayout _layoutFromColumnCount(int count, int rowNumber) {
  if (count == 9) return _BulkSnackLayout.priced;
  if (count == 8) return _BulkSnackLayout.legacy;
  throw BulkSnackParseException(
    rowNumber,
    'unsupported bulk upload layout; expected 8 or 9 columns',
  );
}

String _headerToken(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

List<String> _splitBulkRow(String row, String delimiter) {
  final values = <String>[];
  var current = '';
  var inQuotes = false;

  for (var index = 0; index < row.length; index++) {
    final char = row[index];
    final nextChar = index + 1 < row.length ? row[index + 1] : '';
    if (char == '"') {
      if (inQuotes && nextChar == '"') {
        current += '"';
        index++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (!inQuotes && char == delimiter) {
      values.add(current.trim());
      current = '';
    } else {
      current += char;
    }
  }
  values.add(current.trim());
  return values;
}

bool _parseBoolToken(String raw, {required bool defaultValue}) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return defaultValue;
  if ({'true', 'yes', 'y', '1', 'default', 'active'}.contains(normalized)) {
    return true;
  }
  if ({'false', 'no', 'n', '0', 'inactive'}.contains(normalized)) {
    return false;
  }
  return defaultValue;
}
