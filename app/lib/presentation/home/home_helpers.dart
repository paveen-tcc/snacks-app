import '../../core/constants/snack_categories.dart';
import '../../data/local/app_database.dart';
import 'bloc/home_bloc.dart';

/// Pure helpers shared by the Food/Drink tabs, cart and status banner
/// (extracted verbatim from the original `home_screen.dart` so behaviour is
/// unchanged).

bool hasCutoffPassed(String cutoffTime) {
  final parts = cutoffTime.split(':');
  if (parts.length != 2) return false;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return false;
  final now = DateTime.now();
  final cutoff = DateTime(now.year, now.month, now.day, hour, minute);
  return now.isAfter(cutoff);
}

bool isWithinTimeRange(String startTime, String endTime) {
  final startParts = startTime.split(':');
  final endParts = endTime.split(':');
  if (startParts.length != 2 || endParts.length != 2) return false;
  final startHour = int.tryParse(startParts[0]);
  final startMinute = int.tryParse(startParts[1]);
  final endHour = int.tryParse(endParts[0]);
  final endMinute = int.tryParse(endParts[1]);
  if (startHour == null ||
      startMinute == null ||
      endHour == null ||
      endMinute == null) {
    return false;
  }
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day, startHour, startMinute);
  final end = DateTime(now.year, now.month, now.day, endHour, endMinute);
  return !now.isBefore(start) && !now.isAfter(end);
}

bool isOrderingClosed(HomeLoaded state) {
  if (state.advanceOrderMode) {
    return !isWithinTimeRange(state.advanceWindowStart, state.advanceWindowEnd);
  }
  return hasCutoffPassed(state.cutoffTime);
}

String formatCutoffTime(String cutoffTime) {
  final parts = cutoffTime.split(':');
  if (parts.length != 2) return '12:00 PM';
  final hour = int.tryParse(parts[0]) ?? 12;
  final minute = parts[1];
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  return '$displayHour:$minute $period';
}

String formatTimeRange(String startTime, String endTime) {
  return '${formatCutoffTime(startTime)} - ${formatCutoffTime(endTime)}';
}

String formatOrderWindowCloseTime(HomeLoaded state) {
  return formatCutoffTime(
    state.advanceOrderMode ? state.advanceWindowEnd : state.cutoffTime,
  );
}

String formatAdvanceOrderDate() {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final tomorrowUtc = DateTime.now().toUtc().add(const Duration(days: 1));
  final weekday = weekdays[tomorrowUtc.weekday - 1];
  final month = months[tomorrowUtc.month - 1];
  return '$weekday, $month ${tomorrowUtc.day}, ${tomorrowUtc.year}';
}

bool hasSameSnackSelection(
  List<LocalOrder> todaysOrders,
  List<String> selectedSnackIds,
) {
  if (todaysOrders.length != selectedSnackIds.length) return false;
  final a = todaysOrders.map((order) => order.snackId).toList()..sort();
  final b = List<String>.from(selectedSnackIds)..sort();
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool hasSavedOrder(HomeLoaded state) {
  return state.confirmedSnackIds.isNotEmpty;
}

bool hasSnackSelectionChanges(HomeLoaded state) {
  if (state.confirmedSnackIds.isEmpty && state.selectedSnackIds.isEmpty) {
    return false;
  }
  if (state.confirmedSnackIds.length != state.selectedSnackIds.length) {
    return true;
  }
  final a = List<String>.from(state.confirmedSnackIds)..sort();
  final b = List<String>.from(state.selectedSnackIds)..sort();
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return true;
  }
  return false;
}

bool hasOrderChanges(HomeLoaded state) {
  return hasSnackSelectionChanges(state);
}

bool isOrderPlaced(HomeLoaded state) {
  return hasSavedOrder(state) && !hasOrderChanges(state);
}

List<LocalSnack> selectedSnacks(HomeLoaded state) {
  final snacksById = {for (final snack in state.snacks) snack.id: snack};
  return state.selectedSnackIds
      .map((id) => snacksById[id])
      .whereType<LocalSnack>()
      .toList();
}

List<String> buildCategoryOptions(List<LocalSnack> snacks) {
  final categories =
      snacks
          .map((snack) => displaySnackCategory(snack.category))
          .toSet()
          .toList()
        ..sort((a, b) {
          final rankCompare = snackCategoryRank(
            a,
          ).compareTo(snackCategoryRank(b));
          if (rankCompare != 0) return rankCompare;
          return a.toLowerCase().compareTo(b.toLowerCase());
        });
  return ['All', ...categories];
}
