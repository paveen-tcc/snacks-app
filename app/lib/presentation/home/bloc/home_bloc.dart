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

  HomeLoaded({
    required this.snacks,
    this.todaysOrder,
    this.filter = 'All',
    this.selectedSnackId,
    this.isSubmitting = false,
    this.drinks = const [],
    this.selectedDrinkId,
    this.isDrinkSubmitting = false,
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

// ---------- BLoC ----------

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final SnackRepository _snackRepo = locator<SnackRepository>();
  final OrderRepository _orderRepo = locator<OrderRepository>();
  final DrinkRepository _drinkRepo = locator<DrinkRepository>();

  StreamSubscription? _snacksSub;
  StreamSubscription? _orderSub;

  // Buffer drinks if they load before HomeLoaded state is set
  List<Map<String, dynamic>>? _pendingDrinks;
  String? _pendingVoteId;

  HomeBloc() : super(HomeLoading()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<SnacksUpdated>(_onSnacksUpdated);
    on<OrderUpdated>(_onOrderUpdated);
    on<ChangeFilter>(_onChangeFilter);
    on<SelectSnack>(_onSelectSnack);
    on<SubmitOrder>(_onSubmitOrder);
    on<DrinksLoaded>(_onDrinksLoaded);
    on<SelectDrink>(_onSelectDrink);

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
      String? defaultSelection = curr.selectedSnackId;
      if (defaultSelection == null) {
        if (curr.todaysOrder != null) {
          defaultSelection = curr.todaysOrder!.snackId;
        } else {
          try {
            defaultSelection = event.snacks.firstWhere((s) => s.isDefault).id;
          } catch (_) {}
        }
      }
      emit(curr.copyWith(snacks: event.snacks, selectedSnackId: defaultSelection));
    } else {
      // Apply any drinks that loaded before state became HomeLoaded
      final drinks = _pendingDrinks ?? [];
      final voteId = _pendingVoteId;
      _pendingDrinks = null;
      _pendingVoteId = null;
      emit(HomeLoaded(
        snacks: event.snacks,
        selectedSnackId: event.snacks.isNotEmpty
            ? event.snacks.firstWhere((s) => s.isDefault, orElse: () => event.snacks.first).id
            : null,
        drinks: drinks,
        selectedDrinkId: voteId,
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

  @override
  Future<void> close() {
    _snacksSub?.cancel();
    _orderSub?.cancel();
    return super.close();
  }
}
