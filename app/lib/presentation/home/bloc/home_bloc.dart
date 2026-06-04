import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/snack_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/drink_repository.dart';
import '../../../core/di/locator.dart';
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
  final List<Map<String, dynamic>> drinks;
  final String? selectedDrinkId;
  final String? confirmedDrinkId;
  final bool isDrinkSubmitting;
  final bool isShutdown;
  final String? shutdownReason;
  final String? shutdownType;
  final String cutoffTime;
  final bool advanceOrderMode;
  final String advanceWindowStart;
  final String advanceWindowEnd;

  HomeLoaded({
    required this.snacks,
    this.todaysOrders = const [],
    this.filter = 'All',
    this.selectedSnackIds = const [],
    this.confirmedSnackIds = const [],
    this.isSubmitting = false,
    this.drinks = const [],
    this.selectedDrinkId,
    this.confirmedDrinkId,
    this.isDrinkSubmitting = false,
    this.isShutdown = false,
    this.shutdownReason,
    this.shutdownType,
    this.cutoffTime = '12:00',
    this.advanceOrderMode = false,
    this.advanceWindowStart = '06:00',
    this.advanceWindowEnd = '22:00',
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
    List<Map<String, dynamic>>? drinks,
    Object? selectedDrinkId = _unset,
    Object? confirmedDrinkId = _unset,
    bool? isDrinkSubmitting,
    bool? isShutdown,
    Object? shutdownReason = _unset,
    Object? shutdownType = _unset,
    String? cutoffTime,
    bool? advanceOrderMode,
    String? advanceWindowStart,
    String? advanceWindowEnd,
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
      drinks: drinks ?? this.drinks,
      selectedDrinkId: selectedDrinkId == _unset
          ? this.selectedDrinkId
          : selectedDrinkId as String?,
      confirmedDrinkId: confirmedDrinkId == _unset
          ? this.confirmedDrinkId
          : confirmedDrinkId as String?,
      isDrinkSubmitting: isDrinkSubmitting ?? this.isDrinkSubmitting,
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
    );
  }
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

class DrinksLoaded extends HomeEvent {
  final List<Map<String, dynamic>> drinks;
  final String? todayVoteId;
  DrinksLoaded(this.drinks, this.todayVoteId);
}

class SelectDrink extends HomeEvent {
  final String drinkId;
  SelectDrink(this.drinkId);
}

class ClearDrinkSelection extends HomeEvent {}

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
  final DrinkRepository _drinkRepo = locator<DrinkRepository>();

  StreamSubscription? _snacksSub;
  StreamSubscription? _orderSub;

  // Buffer drinks/status if they load before HomeLoaded state is set
  List<Map<String, dynamic>>? _pendingDrinks;
  String? _pendingVoteId;
  Map<String, dynamic>? _pendingStatus;
  PublicSettings? _pendingSettings;
  List<LocalOrder>? _pendingOrders;

  HomeBloc() : super(HomeLoading()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<SnacksUpdated>(_onSnacksUpdated);
    on<OrderUpdated>(_onOrderUpdated);
    on<ChangeFilter>(_onChangeFilter);
    on<ToggleSnack>(_onToggleSnack);
    on<SubmitOrder>(_onSubmitOrder);
    on<DrinksLoaded>(_onDrinksLoaded);
    on<SelectDrink>(_onSelectDrink);
    on<ClearDrinkSelection>(_onClearDrinkSelection);
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

    _snackRepo.syncSnacks();

    // Load drinks in background
    Future.wait([_drinkRepo.fetchDrinks(), _drinkRepo.getTodayVote()])
        .then((results) {
          final drinks = results[0] as List<Map<String, dynamic>>;
          final todayVote = results[1] as String?;
          add(DrinksLoaded(drinks, todayVote));
        })
        .catchError((e) {
          print('Drink load error: $e');
          return null;
        });

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
      emit(
        curr.copyWith(
          snacks: event.snacks,
          selectedSnackIds: selection,
          confirmedSnackIds: curr.confirmedSnackIds
              .where(
                (confirmedId) =>
                    event.snacks.any((snack) => snack.id == confirmedId),
              )
              .toList(),
        ),
      );
    } else {
      // Apply any drinks/status that loaded before state became HomeLoaded
      final drinks = _pendingDrinks ?? [];
      final voteId = _pendingVoteId;
      final status = _pendingStatus;
      final settings = _pendingSettings;
      final orders = _pendingOrders ?? const <LocalOrder>[];
      _pendingDrinks = null;
      _pendingVoteId = null;
      _pendingStatus = null;
      _pendingSettings = null;
      _pendingOrders = null;
      emit(
        HomeLoaded(
          snacks: event.snacks,
          todaysOrders: orders,
          selectedSnackIds: orders.map((order) => order.snackId).toList(),
          confirmedSnackIds: orders.map((order) => order.snackId).toList(),
          drinks: drinks,
          selectedDrinkId: voteId,
          confirmedDrinkId: voteId,
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
      emit(
        curr.copyWith(
          todaysOrders: event.orders,
          confirmedSnackIds: event.orders
              .map((order) => order.snackId)
              .toList(),
          selectedSnackIds: event.orders.isNotEmpty
              ? event.orders.map((order) => order.snackId).toList()
              : curr.selectedSnackIds,
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
      if (selectedSnackIds.contains(event.snackId)) {
        selectedSnackIds.remove(event.snackId);
      } else {
        selectedSnackIds.add(event.snackId);
      }
      emit(curr.copyWith(selectedSnackIds: selectedSnackIds));
    }
  }

  Future<void> _onSubmitOrder(
    SubmitOrder event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final curr = state as HomeLoaded;
    final confirmedSnackIds = curr.confirmedSnackIds.toSet();
    final selectedSnackIds = curr.selectedSnackIds.toSet();
    final snackChanged =
        confirmedSnackIds.length != selectedSnackIds.length ||
        !confirmedSnackIds.containsAll(selectedSnackIds);
    final drinkChanged = curr.selectedDrinkId != curr.confirmedDrinkId;

    if ((!snackChanged && !drinkChanged) ||
        curr.isSubmitting ||
        curr.isDrinkSubmitting) {
      return;
    }

    emit(curr.copyWith(isSubmitting: true, isDrinkSubmitting: true));
    try {
      if (snackChanged) {
        if (curr.selectedSnackIds.isEmpty) {
          await _orderRepo.clearOrder();
        } else {
          await _orderRepo.placeOrder(curr.selectedSnackIds);
        }
      }
      if (drinkChanged) {
        final drinkId = curr.selectedDrinkId;
        if (drinkId == null) {
          await _drinkRepo.clearVote();
        } else {
          await _drinkRepo.castVote(drinkId);
        }
      }
      emit(
        (state as HomeLoaded).copyWith(
          isSubmitting: false,
          isDrinkSubmitting: false,
          confirmedSnackIds: curr.selectedSnackIds,
          confirmedDrinkId: curr.selectedDrinkId,
        ),
      );
    } catch (e) {
      emit(curr.copyWith(isSubmitting: false, isDrinkSubmitting: false));
      print(e);
    }
  }

  void _onDrinksLoaded(DrinksLoaded event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      emit(
        curr.copyWith(
          drinks: event.drinks,
          selectedDrinkId: event.todayVoteId,
          confirmedDrinkId: event.todayVoteId,
        ),
      );
    } else {
      // State not ready yet — buffer for when snacks arrive
      _pendingDrinks = event.drinks;
      _pendingVoteId = event.todayVoteId;
    }
  }

  Future<void> _onSelectDrink(
    SelectDrink event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final curr = state as HomeLoaded;
    if (curr.isSubmitting) return;
    emit(curr.copyWith(selectedDrinkId: event.drinkId));
  }

  Future<void> _onClearDrinkSelection(
    ClearDrinkSelection event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final curr = state as HomeLoaded;
    if (curr.selectedDrinkId == null || curr.isSubmitting) return;
    emit(curr.copyWith(selectedDrinkId: null));
  }

  Future<void> _onRefreshHome(
    RefreshHome event,
    Emitter<HomeState> emit,
  ) async {
    // Re-sync from server without showing loading spinner
    _snackRepo.syncSnacks();

    // Refresh drinks
    Future.wait([_drinkRepo.fetchDrinks(), _drinkRepo.getTodayVote()])
        .then((results) {
          final drinks = results[0] as List<Map<String, dynamic>>;
          final todayVote = results[1] as String?;
          add(DrinksLoaded(drinks, todayVote));
        })
        .catchError((e) {
          print('Drink refresh error: $e');
          return null;
        });

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
