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
  final LocalOrder? todaysOrder;
  final String filter;
  final String? selectedSnackId;
  final bool isSubmitting;
  final List<Map<String, dynamic>> drinks;
  final String? selectedDrinkId;
  final bool isDrinkSubmitting;
  final bool isShutdown;
  final String? shutdownReason;
  final String? shutdownType;
  final String cutoffTime;

  HomeLoaded({
    required this.snacks,
    this.todaysOrder,
    this.filter = 'All',
    this.selectedSnackId,
    this.isSubmitting = false,
    this.drinks = const [],
    this.selectedDrinkId,
    this.isDrinkSubmitting = false,
    this.isShutdown = false,
    this.shutdownReason,
    this.shutdownType,
    this.cutoffTime = '12:00',
  });

  // Sentinel to distinguish "pass null explicitly" from "not provided"
  static const _unset = Object();

  HomeLoaded copyWith({
    List<LocalSnack>? snacks,
    Object? todaysOrder = _unset,
    String? filter,
    Object? selectedSnackId = _unset,
    bool? isSubmitting,
    List<Map<String, dynamic>>? drinks,
    Object? selectedDrinkId = _unset,
    bool? isDrinkSubmitting,
    bool? isShutdown,
    Object? shutdownReason = _unset,
    Object? shutdownType = _unset,
    String? cutoffTime,
  }) {
    return HomeLoaded(
      snacks: snacks ?? this.snacks,
      todaysOrder: todaysOrder == _unset ? this.todaysOrder : todaysOrder as LocalOrder?,
      filter: filter ?? this.filter,
      selectedSnackId: selectedSnackId == _unset ? this.selectedSnackId : selectedSnackId as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      drinks: drinks ?? this.drinks,
      selectedDrinkId: selectedDrinkId == _unset ? this.selectedDrinkId : selectedDrinkId as String?,
      isDrinkSubmitting: isDrinkSubmitting ?? this.isDrinkSubmitting,
      isShutdown: isShutdown ?? this.isShutdown,
      shutdownReason: shutdownReason == _unset ? this.shutdownReason : shutdownReason as String?,
      shutdownType: shutdownType == _unset ? this.shutdownType : shutdownType as String?,
      cutoffTime: cutoffTime ?? this.cutoffTime,
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
  final LocalOrder? order;
  OrderUpdated(this.order);
}

class ChangeFilter extends HomeEvent {
  final String filter;
  ChangeFilter(this.filter);
}

class SelectSnack extends HomeEvent {
  final String snackId;
  SelectSnack(this.snackId);
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

class RefreshHome extends HomeEvent {}

class CutoffLoaded extends HomeEvent {
  final String cutoffTime;
  CutoffLoaded(this.cutoffTime);
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
  String? _pendingCutoff;

  HomeBloc() : super(HomeLoading()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<SnacksUpdated>(_onSnacksUpdated);
    on<OrderUpdated>(_onOrderUpdated);
    on<ChangeFilter>(_onChangeFilter);
    on<SelectSnack>(_onSelectSnack);
    on<SubmitOrder>(_onSubmitOrder);
    on<DrinksLoaded>(_onDrinksLoaded);
    on<SelectDrink>(_onSelectDrink);
    on<StatusLoaded>(_onStatusLoaded);
    on<RefreshHome>(_onRefreshHome);
    on<CutoffLoaded>(_onCutoffLoaded);

    add(LoadHomeData());
  }

  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());

    _snackRepo.syncSnacks();
    _orderRepo.syncTodayOrder();

    // Load drinks in background
    Future.wait([
      _drinkRepo.fetchDrinks(),
      _drinkRepo.getTodayVote(),
    ]).then((results) {
      final drinks = results[0] as List<Map<String, dynamic>>;
      final todayVote = results[1] as String?;
      add(DrinksLoaded(drinks, todayVote));
    }).catchError((e) => print('Drink load error: $e'));

    // Check if today is a shutdown/holiday day
    _orderRepo.fetchTodayStatus().then((status) {
      final isOpen = status['isOpen'] as bool? ?? true;
      add(StatusLoaded(!isOpen, status['reason'] as String?, status['type'] as String?));
    });

    // Fetch cutoff time
    _snackRepo.fetchCutoffTime().then((time) => add(CutoffLoaded(time)));

    _snacksSub?.cancel();
    _snacksSub = _snackRepo.watchActiveSnacks().listen((snacks) {
      add(SnacksUpdated(snacks));
    });

    _orderSub?.cancel();
    _orderSub = _orderRepo.watchTodayOrder().listen((order) {
      add(OrderUpdated(order));
    });
  }

  void _onSnacksUpdated(SnacksUpdated event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      // Re-evaluate selection: use today's order, then default snack, then keep current
      String? selection;
      if (curr.todaysOrder != null) {
        selection = curr.todaysOrder!.snackId;
      } else {
        try {
          selection = event.snacks.firstWhere((s) => s.isDefault).id;
        } catch (_) {
          selection = curr.selectedSnackId;
        }
      }
      emit(curr.copyWith(snacks: event.snacks, selectedSnackId: selection));
    } else {
      // Apply any drinks/status that loaded before state became HomeLoaded
      final drinks = _pendingDrinks ?? [];
      final voteId = _pendingVoteId;
      final status = _pendingStatus;
      final cutoff = _pendingCutoff;
      _pendingDrinks = null;
      _pendingVoteId = null;
      _pendingStatus = null;
      _pendingCutoff = null;
      emit(HomeLoaded(
        snacks: event.snacks,
        selectedSnackId: event.snacks.isNotEmpty
            ? event.snacks.firstWhere((s) => s.isDefault, orElse: () => event.snacks.first).id
            : null,
        drinks: drinks,
        selectedDrinkId: voteId,
        isShutdown: status?['isShutdown'] as bool? ?? false,
        shutdownReason: status?['reason'] as String?,
        shutdownType: status?['type'] as String?,
        cutoffTime: cutoff ?? '12:00',
      ));
    }
  }

  void _onOrderUpdated(OrderUpdated event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      emit(curr.copyWith(
        todaysOrder: event.order,
        selectedSnackId: event.order?.snackId ?? curr.selectedSnackId,
      ));
    }
  }

  void _onChangeFilter(ChangeFilter event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(filter: event.filter));
    }
  }

  void _onSelectSnack(SelectSnack event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(selectedSnackId: event.snackId));
    }
  }

  Future<void> _onSubmitOrder(SubmitOrder event, Emitter<HomeState> emit) async {
    if (state is! HomeLoaded) return;
    final curr = state as HomeLoaded;
    if (curr.selectedSnackId == null || curr.isSubmitting) return;

    emit(curr.copyWith(isSubmitting: true));
    try {
      await _orderRepo.placeOrder(curr.selectedSnackId!);
      emit(curr.copyWith(isSubmitting: false));
    } catch (e) {
      emit(curr.copyWith(isSubmitting: false));
      print(e);
    }
  }

  void _onDrinksLoaded(DrinksLoaded event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      emit(curr.copyWith(drinks: event.drinks, selectedDrinkId: event.todayVoteId));
    } else {
      // State not ready yet — buffer for when snacks arrive
      _pendingDrinks = event.drinks;
      _pendingVoteId = event.todayVoteId;
    }
  }

  Future<void> _onSelectDrink(SelectDrink event, Emitter<HomeState> emit) async {
    if (state is! HomeLoaded) return;
    final curr = state as HomeLoaded;
    emit(curr.copyWith(selectedDrinkId: event.drinkId, isDrinkSubmitting: true));
    try {
      await _drinkRepo.castVote(event.drinkId);
    } catch (e) {
      print('Vote error: $e');
    } finally {
      if (state is HomeLoaded) {
        emit((state as HomeLoaded).copyWith(isDrinkSubmitting: false));
      }
    }
  }

  Future<void> _onRefreshHome(RefreshHome event, Emitter<HomeState> emit) async {
    // Re-sync from server without showing loading spinner
    _snackRepo.syncSnacks();
    _orderRepo.syncTodayOrder();

    // Refresh drinks
    Future.wait([
      _drinkRepo.fetchDrinks(),
      _drinkRepo.getTodayVote(),
    ]).then((results) {
      final drinks = results[0] as List<Map<String, dynamic>>;
      final todayVote = results[1] as String?;
      add(DrinksLoaded(drinks, todayVote));
    }).catchError((e) => print('Drink refresh error: $e'));

    // Refresh shutdown status
    _orderRepo.fetchTodayStatus().then((status) {
      final isOpen = status['isOpen'] as bool? ?? true;
      add(StatusLoaded(!isOpen, status['reason'] as String?, status['type'] as String?));
    });

    // Refresh cutoff time
    _snackRepo.fetchCutoffTime().then((time) => add(CutoffLoaded(time)));
  }

  void _onCutoffLoaded(CutoffLoaded event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(cutoffTime: event.cutoffTime));
    } else {
      _pendingCutoff = event.cutoffTime;
    }
  }

  void _onStatusLoaded(StatusLoaded event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final curr = state as HomeLoaded;
      emit(curr.copyWith(
        isShutdown: event.isShutdown,
        shutdownReason: event.reason,
        shutdownType: event.type,
      ));
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
