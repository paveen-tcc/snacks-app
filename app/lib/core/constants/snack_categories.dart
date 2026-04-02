const List<String> snackCategoryOrder = [
  'Pizza',
  'Sandwich',
  'Burger',
  'Fries',
  'Roll',
  'Momos',
  'Fingers Fried',
  'Chicken Varieties',
  'Samosa',
];

String displaySnackCategory(String? category) {
  final trimmed = category?.trim() ?? '';
  return trimmed.isEmpty ? 'General' : trimmed;
}

int snackCategoryRank(String category) {
  final index = snackCategoryOrder.indexOf(category);
  return index >= 0 ? index : snackCategoryOrder.length;
}

String normalizeSnackCategory(String? category) {
  return displaySnackCategory(category).toLowerCase();
}
