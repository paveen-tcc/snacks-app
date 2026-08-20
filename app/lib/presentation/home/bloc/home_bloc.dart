import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/snack_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/di/locator.dart';
import '../home_helpers.dart';
import 'dart:async';

// ---------- State ----------

abstract class HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<LocalSnack> snacks;
  final List<LocalOrder> todaysOrders;
  final String filter;
  final List<String> selectedSnackIds;
  final List<String> confirmedSnackIds;
  final bool isSubmitting;
  final bool isShutdown;
  final String? shutdownReason;
  final String? shutdownType;
  final String cutoffTime;
  final bool advanceOrderMode;
  final String advanceWindowStart;
  final String advanceWindowEnd;
  /// Per-drink sugar-free preference (snackId → isSugarFree).
  final Map<String, bool> sugarFreePrefs;
  /// Confirmed per-drink sugar-free preference (snackId → isSugarFree).
  final Map<String, bool> confirmedSugarFreePrefs;
  /// Transient message to surface when an order mutation is rejected (e.g. the
  /// ordering window has closed). Consumed by a BlocListener; [errorNonce]
  /// increments on each new error so identical messages still re-trigger.
  final String? orderError;
  final int errorNonce;

  HomeLoaded({
    required this.snacks,
    this.todaysOrders = const [],
    this.filter = 'All',
    this.selectedSnackIds = const [],
    this.confirmedSnackIds = const [],
    this.isSubmitting = false,
    this.isShutdown = false,
    this.shutdownReason,
    this.shutdownType,
    this.cutoffTime = '12:00',
    this.advanceOrderMode = false,
    this.advanceWindowStart = '06:00',
    this.advanceWindowEnd = '22:00',
    this.sugarFreePrefs = const {},
    this.confirmedSugarFreePrefs = const {},
    this.orderError,
    this.errorNonce = 0,
  });

  // Sentinel to distinguish "pass null explicitly" from "not provided"
  static const _unset = Object();

  HomeLoaded copyWith({
    List<LocalSnack>? snacks,
    Object? todaysOrders = _unset,
    String? filter,
    List<String>? selectedSnackIds,
    List<String>? confirmedSnackIds,
    bool? isSubmitting,
    bool? isShutdown,
    Object? shutdownReason = _unset,
    Object? shutdownType = _unset,
    String? cutoffTime,
    bool? advanceOrderMode,
    String? advanceWindowStart,
    String? advanceWindowEnd,
    Map<String, bool>? sugarFreePrefs,
    Map<String, bool>? confirmedSugarFreePrefs,
    Object? orderError = _unset,
    int? errorNonce,
  }) {
    return HomeLoaded(
      snacks: snacks ?? this.snacks,
      todaysOrders: todaysOrders == _unset
          ? this.todaysOrders
          : todaysOrders as List<LocalOrder>,
      filter: filter ?? this.filter,
      selectedSnackIds: selectedSnackIds ?? this.selectedSnackIds,
      confirmedSnackIds: confirmedSnackIds ?? this.confirmedSnackIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isShutdown: isShutdown ?? this.isShutdown,
      shutdownReason: shutdownReason == _unset
          ? this.shutdownReason
          : shutdownReason as String?,
      shutdownType: shutdownType == _unset
          ? this.shutdownType
          : shutdownType as String?,
      cutoffTime: cutoffTime ?? this.cutoffTime,
      advanceOrderMode: advanceOrderMode ?? this.advanceOrderMode,
      advanceWindowStart: advanceWindowStart ?? this.advanceWindowStart,
      advanceWindowEnd: advanceWindowEnd ?? this.advanceWindowEnd,
      sugarFreePrefs: sugarFreePrefs ?? this.sugarFreePrefs,
      confirmedSugarFreePrefs: confirmedSugarFreePrefs ?? this.confirmedSugarFreePrefs,
      orderError: orderError == _unset
          ? this.orderError
          : orderError as String?,
      errorNonce: errorNonce ?? this.errorNonce,
    );
  }
}

/// Rebuilds the sugar-free preference map from persisted order rows.
Map<String, bool> _sugarPrefsFromOrders(List<LocalOrder> orders) {
  final prefs = <String, bool>{};
  for (final order in orders) {
    if (order.sugarFree) prefs[order.snackId] = true;
  }
  return prefs;
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

// ---------- Events ----------

abstract class HomeEvent {}

class LoadHomeData extends HomeEvent {}

class SnacksUpdated extends HomeEvent {
  final List<LocalSnack> snacks;
  SnacksUpdated(this.snacks);
}

class OrderUpdated extends HomeEvent {
  final List<LocalOrder> orders;
  OrderUpdated(this.orders);
}

class ChangeFilter extends HomeEvent {
  final String filter;
  ChangeFilter(this.filter);
}

class ToggleSnack extends HomeEvent {
  final String snackId;
  ToggleSnack(this.snackId);
}

class SubmitOrder extends HomeEvent {}

class IncrementSnack extends HomeEvent {
  final String snackId;
  IncrementSnack(this.snackId);
}

class DecrementSnack extends HomeEvent {
  final String snackId;
  DecrementSnack(this.snackId);
}

class ToggleSugarFree extends HomeEvent {
  final String snackId;
  ToggleSugarFree(this.snackId);
}

class RefreshHome extends HomeEvent {}

class SettingsLoaded extends HomeEvent {
  final PublicSettings settings;
  SettingsLoaded(this.settings);
}

class StatusLoaded extends HomeEvent {
  final bool isShutdown;
  final String? reason;
  final String? type;
  StatusLoaded(this.isShutdown, this.reason, this.type);
}

// ---------- BLoC ----------

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final SnackRepository _snackRepo = locator<SnackRepository>();
  final OrderRepository _orderRepo = locator<OrderRepository>();

  StreamSubscription? _snacksSub;
  StreamSubscription? _orderSub;

  Map<String, dynamic>? _pendingStatus;
  PublicSettings? _pendingSettings;
  List<LocalOrder>? _pendingOrders;

  HomeBloc() : super(HomeLoading()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<SnacksUpdated>(_onSnacksUpdated);
    on<OrderUpdated>(_onOrderUpdated);
    on<ChangeFilter>(_onChangeFilter);
    on<ToggleSnack>(_onToggleSnack);
    on<IncrementSnack>(_onIncrementSnack);
    on<DecrementSnack>(_onDecrementSnack);
    on<ToggleSugarFree>(_onToggleSugarFree);
    on<SubmitOrder>(_onSubmitOrder);
    on<StatusLoaded>(_onStatusLoaded);
    on<RefreshHome>(_onRefreshHome);
    on<SettingsLoaded>(_onSettingsLoaded);

    add(LoadHomeData());
  }

  void _watchOrders() {
    _orderSub?.cancel();
    _orderSub = _orderRepo.watchTodayOrder().listen((orders) {
      add(OrderUpdated(orders));
    });
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    _snackRepo.syncSnacks().then((_) => _snackRepo.precacheImages());

    // Check if today is a shutdown/holiday day
    _orderRepo.fetchTodayStatus().then((status) {
      final isOpen = status['isOpen'] as bool? ?? true;
      add(
        StatusLoaded(
          !isOpen,
          status['reason'] as String?,
          status['type'] as String?,
        ),
      );
    });

    final settings = await _snackRepo.fetchPublicSettings();
    add(SettingsLoaded(settings));
    await _orderRepo.syncTodayOrder();

    _snacksSub?.cancel();
    _snacksSub = _snackRepo.watchActiveSnacks().listen((snacks) {
      add(SnacksUpdated(snacks));
    });

    _watchOrders();
  }

  void _onSnacksUpdated(SnacksUpdated event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      final selection = curr.selectedSnackIds
          .where(
            (selectedId) => event.snacks.any((snack) => snack.id == selectedId),
          )
          .toList();
      bool snackExists(String id) => event.snacks.any((snack) => snack.id == id);
      Map<String, bool> filterPrefs(Map<String, bool> prefs) => {
        for (final entry in prefs.entries)
          if (snackExists(entry.key)) entry.key: entry.value,
      };
      emit(
        curr.copyWith(
          snacks: event.snacks,
          selectedSnackIds: selection,
          confirmedSnackIds: curr.confirmedSnackIds
              .where((confirmedId) => snackExists(confirmedId))
              .toList(),
          sugarFreePrefs: filterPrefs(curr.sugarFreePrefs),
          confirmedSugarFreePrefs: filterPrefs(curr.confirmedSugarFreePrefs),
        ),
      );
    } else {
      final status = _pendingStatus;
      final settings = _pendingSettings;
      final orders = _pendingOrders ?? const <LocalOrder>[];
      _pendingStatus = null;
      _pendingSettings = null;
      _pendingOrders = null;
      final sugarPrefs = _sugarPrefsFromOrders(orders);
      emit(
        HomeLoaded(
          snacks: event.snacks,
          todaysOrders: orders,
          selectedSnackIds: orders.map((order) => order.snackId).toList(),
          confirmedSnackIds: orders.map((order) => order.snackId).toList(),
          sugarFreePrefs: sugarPrefs,
          confirmedSugarFreePrefs: sugarPrefs,
          isShutdown: status?['isShutdown'] as bool? ?? false,
          shutdownReason: status?['reason'] as String?,
          shutdownType: status?['type'] as String?,
          cutoffTime: settings?.cutoffTime ?? '12:00',
          advanceOrderMode: settings?.advanceOrderMode ?? false,
          advanceWindowStart: settings?.advanceWindowStart ?? '06:00',
          advanceWindowEnd: settings?.advanceWindowEnd ?? '22:00',
        ),
      );
    }
  }

  void _onOrderUpdated(OrderUpdated event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      final sugarPrefs = _sugarPrefsFromOrders(event.orders);
      emit(
        curr.copyWith(
          todaysOrders: event.orders,
          confirmedSnackIds: event.orders
              .map((order) => order.snackId)
              .toList(),
          selectedSnackIds: event.orders.isNotEmpty
              ? event.orders.map((order) => order.snackId).toList()
              : curr.selectedSnackIds,
          confirmedSugarFreePrefs: sugarPrefs,
          sugarFreePrefs: event.orders.isNotEmpty
              ? sugarPrefs
              : curr.sugarFreePrefs,
        ),
      );
    } else {
      _pendingOrders = event.orders;
    }
  }

  void _onChangeFilter(ChangeFilter event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(filter: event.filter));
    }
  }

  void _onToggleSnack(ToggleSnack event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      final selectedSnackIds = List<String>.from(curr.selectedSnackIds);
      Map<String, bool>? updatedPrefs;
      if (selectedSnackIds.contains(event.snackId)) {
        selectedSnackIds.removeWhere((id) => id == event.snackId);
        // Clean up sugar-free pref when drink is deselected
        if (curr.sugarFreePrefs.containsKey(event.snackId)) {
          updatedPrefs = Map<String, bool>.from(curr.sugarFreePrefs)
            ..remove(event.snackId);
        }
      } else {
        selectedSnackIds.add(event.snackId);
      }
      emit(curr.copyWith(
        selectedSnackIds: selectedSnackIds,
        sugarFreePrefs: updatedPrefs,
      ));
    }
  }

  void _onIncrementSnack(IncrementSnack event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      final selectedSnackIds = List<String>.from(curr.selectedSnackIds);
      selectedSnackIds.add(event.snackId);
      emit(curr.copyWith(selectedSnackIds: selectedSnackIds));
    }
  }

  void _onDecrementSnack(DecrementSnack event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      final selectedSnackIds = List<String>.from(curr.selectedSnackIds);
      selectedSnackIds.remove(event.snackId);
      // Clean up sugar-free pref when drink count reaches zero
      Map<String, bool>? updatedPrefs;
      if (!selectedSnackIds.contains(event.snackId) &&
          curr.sugarFreePrefs.containsKey(event.snackId)) {
        updatedPrefs = Map<String, bool>.from(curr.sugarFreePrefs)
          ..remove(event.snackId);
      }
      emit(curr.copyWith(
        selectedSnackIds: selectedSnackIds,
        sugarFreePrefs: updatedPrefs,
      ));
    }
  }

  void _onToggleSugarFree(ToggleSugarFree event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      final prefs = Map<String, bool>.from(curr.sugarFreePrefs);
      final current = prefs[event.snackId] ?? false;
      if (!current) {
        prefs[event.snackId] = true;
      } else {
        prefs.remove(event.snackId);
      }
      emit(curr.copyWith(sugarFreePrefs: prefs));
    }
  }

  Future<void> _onSubmitOrder(
    SubmitOrder event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final curr = state as HomeLoaded;

    if (!hasOrderChanges(curr) || curr.isSubmitting) {
      return;
    }

    emit(curr.copyWith(isSubmitting: true, orderError: null));
    try {
      if (curr.selectedSnackIds.isEmpty) {
        await _orderRepo.clearOrder();
      } else {
        await _orderRepo.placeOrder(
          curr.selectedSnackIds,
          sugarFreePrefs: curr.sugarFreePrefs,
        );
      }
      emit(
        (state as HomeLoaded).copyWith(
          isSubmitting: false,
          confirmedSnackIds: curr.selectedSnackIds,
          confirmedSugarFreePrefs: curr.sugarFreePrefs,
        ),
      );
    } catch (e) {
      // A rejected order (e.g. the window closed) has already been rolled back
      // to the server's truth by the repository; surface the reason so the
      // user isn't left thinking a stale selection was saved.
      final latest = state is HomeLoaded ? state as HomeLoaded : curr;
      final message = e is OrderException
          ? e.message
          : 'Could not save your order. Please try again.';
      emit(
        latest.copyWith(
          isSubmitting: false,
          orderError: message,
          errorNonce: latest.errorNonce + 1,
        ),
      );
      debugPrint('Submit order error: $e');
    }
  }

  Future<void> _onRefreshHome(
    RefreshHome event,
    Emitter<HomeState> emit,
  ) async {
    // Re-sync from server without showing loading spinner
    _snackRepo.syncSnacks().then((_) => _snackRepo.precacheImages());

    // Refresh shutdown status
    _orderRepo.fetchTodayStatus().then((status) {
      final isOpen = status['isOpen'] as bool? ?? true;
      add(
        StatusLoaded(
          !isOpen,
          status['reason'] as String?,
          status['type'] as String?,
        ),
      );
    });

    final settings = await _snackRepo.fetchPublicSettings();
    add(SettingsLoaded(settings));
    await _orderRepo.syncTodayOrder();
    _watchOrders();
  }

  void _onSettingsLoaded(SettingsLoaded event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      emit(
        (state as HomeLoaded).copyWith(
          cutoffTime: event.settings.cutoffTime,
          advanceOrderMode: event.settings.advanceOrderMode,
          advanceWindowStart: event.settings.advanceWindowStart,
          advanceWindowEnd: event.settings.advanceWindowEnd,
        ),
      );
    } else {
      _pendingSettings = event.settings;
    }
  }

  void _onStatusLoaded(StatusLoaded event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      emit(
        curr.copyWith(
          isShutdown: event.isShutdown,
          shutdownReason: event.reason,
          shutdownType: event.type,
        ),
      );
    } else {
      _pendingStatus = {
        'isShutdown': event.isShutdown,
        'reason': event.reason,
        'type': event.type,
      };
    }
  }

  @override
  Future<void> close() {
    _snacksSub?.cancel();
    _orderSub?.cancel();
    return super.close();
  }
}
