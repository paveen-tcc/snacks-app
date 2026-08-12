int? parseWholeRupees(String value) {
  final trimmed = value.trim();
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) return null;
  return int.tryParse(trimmed);
}

String formatRupees(num value) => '₹${value.toInt()}';
