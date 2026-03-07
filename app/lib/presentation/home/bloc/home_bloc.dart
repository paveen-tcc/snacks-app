import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/snack_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/di/locator.dart';
import 'dart:async';

// State
abstract class HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<LocalSnack> snacks;
  final LocalOrder? todaysOrder;
  final String filter;
  final String? selectedSnackId;
  final bool isSubmitting;

  HomeLoaded({
    required this.snacks,
    this.todaysOrder,
    this.filter = 'All',
    this.selectedSnackId,
    this.isSubmitting = false,
  });

  HomeLoaded copyWith({
    List<LocalSnack>? snacks,
    LocalOrder? todaysOrder,
    String? filter,
    String? selectedSnackId,
    bool? isSubmitting,
  }) {
    return HomeLoaded(
      snacks: snacks ?? this.snacks,
      todaysOrder: todaysOrder ?? this.todaysOrder,
      filter: filter ?? this.filter,
      selectedSnackId: selectedSnackId ?? this.selectedSnackId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

// Events
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

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final SnackRepository _snackRepo = locator<SnackRepository>();
  final OrderRepository _orderRepo = locator<OrderRepository>();

  StreamSubscription? _snacksSub;
  StreamSubscription? _orderSub;

  HomeBloc() : super(HomeLoading()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<SnacksUpdated>(_onSnacksUpdated);
    on<OrderUpdated>(_onOrderUpdated);
    on<ChangeFilter>(_onChangeFilter);
    on<SelectSnack>(_onSelectSnack);
    on<SubmitOrder>(_onSubmitOrder);

    // Kick off initial load
    add(LoadHomeData());
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    // 1. Kick off background remote sync
    _snackRepo.syncSnacks();
    _orderRepo.syncTodayOrder();

    // 2. Subscribe to reactive local Drift streams
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
      final currState = state as HomeLoaded;

      // Auto-select based on existing order or default
      String? defaultSelection = currState.selectedSnackId;
      if (defaultSelection == null) {
        if (currState.todaysOrder != null) {
          defaultSelection = currState.todaysOrder!.snackId;
        } else {
          try {
            defaultSelection = event.snacks.firstWhere((s) => s.isDefault).id;
          } catch (_) {}
        }
      }

      emit(
        currState.copyWith(
          snacks: event.snacks,
          selectedSnackId: defaultSelection,
        ),
      );
    } else {
      emit(
        HomeLoaded(
          snacks: event.snacks,
          selectedSnackId: event.snacks.isNotEmpty
              ? event.snacks
                    .firstWhere(
                      (s) => s.isDefault,
                      orElse: () => event.snacks.first,
                    )
                    .id
              : null,
        ),
      );
    }
  }

  void _onOrderUpdated(OrderUpdated event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final currState = state as HomeLoaded;
      emit(
        currState.copyWith(
          todaysOrder: event.order,
          selectedSnackId: event.order?.snackId ?? currState.selectedSnackId,
        ),
      );
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

  Future<void> _onSubmitOrder(
    SubmitOrder event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final currState = state as HomeLoaded;
    if (currState.selectedSnackId == null) return;

    // Prevent double submissions
    if (currState.isSubmitting) return;

    emit(currState.copyWith(isSubmitting: true));

    try {
      await _orderRepo.placeOrder(currState.selectedSnackId!);
      // Stream subscription will naturally update the UI once drift DB updates
      emit(currState.copyWith(isSubmitting: false));
    } catch (e) {
      emit(currState.copyWith(isSubmitting: false));
      // In a real app we might want to emit a transient side-effect for a snackbar here
      print(e);
    }
  }

  @override
  Future<void> close() {
    _snacksSub?.cancel();
    _orderSub?.cancel();
    return super.close();
  }
}
