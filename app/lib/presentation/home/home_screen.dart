import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/locator.dart';
import '../../core/constants/snack_categories.dart';
import '../../core/theme/notion_theme.dart';
import '../../core/widgets/illustrations.dart';
import '../../data/repositories/auth_repository.dart';
import 'bloc/home_bloc.dart';
import '../../data/local/app_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeBloc _homeBloc;
  String _username = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _homeBloc = HomeBloc();
    _refreshViewerState();
  }

  bool _isAdmin = false;

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    final isAdmin = prefs.getBool('is_admin') ?? false;
    if (mounted) {
      setState(() {
        _username = username;
        _isAdmin = isAdmin;
      });
    }
  }

  Future<void> _refreshViewerState() async {
    try {
      await locator<AuthRepository>().refreshSession();
    } catch (_) {
      // Keep existing cached session state if refresh fails.
    }
    await _loadUsername();
  }

  @override
  void dispose() {
    _homeBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeBloc,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Scaffold(body: Center(child: FoodLoader()));
          }

          if (state is! HomeLoaded) {
            return const Scaffold(
              body: Center(child: Text('Something went wrong')),
            );
          }

          final isVegMode = state.filter == 'Veg';
          final displayedSnacks = state.snacks
              .where((snack) => !isVegMode || snack.isVeg == true)
              .toList();
          final isCutoffClosed = _hasCutoffPassed(state.cutoffTime);
          final categoryOptions = _buildCategoryOptions(displayedSnacks);
          final selectedCategory = categoryOptions.contains(_selectedCategory)
              ? _selectedCategory
              : 'All';
          final filteredSnacks =
              selectedCategory == 'All' || selectedCategory == 'Drinks'
              ? displayedSnacks
              : displayedSnacks
                    .where(
                      (snack) =>
                          displaySnackCategory(snack.category) ==
                          selectedCategory,
                    )
                    .toList();

          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Hello, ${_username.isNotEmpty ? _username : 'there'} 👋',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    context.push('/history');
                  },
                ),
                if (_isAdmin)
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => context.push('/admin'),
                  ),
              ],
            ),
            body: state.isShutdown
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ShutdownIllustration(width: 220),
                          const SizedBox(height: 24),
                          Text(
                            state.shutdownType == 'holiday'
                                ? 'Happy Holiday!'
                                : 'No Orders Today',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.shutdownReason ??
                                'The kitchen is taking a break today',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: NotionTheme.secondaryText),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: NotionTheme.surfaceSelected,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: NotionTheme.blueAccent.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  state.shutdownType == 'holiday'
                                      ? Icons.celebration
                                      : Icons.info_outline,
                                  color: NotionTheme.blueAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Orders will resume on the next working day',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: NotionTheme.blueAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _homeBloc.add(RefreshHome());
                      await _refreshViewerState();
                      // Wait a bit for the sync to propagate
                      await Future.delayed(const Duration(milliseconds: 800));
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatusCard(context),
                                const SizedBox(height: 24),
                                _buildMenuHeader(state),
                                if (!isCutoffClosed) ...[
                                  const SizedBox(height: 20),
                                  _buildCategoryScroller(
                                    categoryOptions,
                                    selectedCategory,
                                  ),
                                ],
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          sliver: SliverToBoxAdapter(
                            child: _buildCategoryContent(
                              state,
                              filteredSnacks,
                              selectedCategory,
                              isCutoffClosed,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
            bottomNavigationBar: state.isShutdown || isCutoffClosed
                ? null
                : Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                    decoration: const BoxDecoration(
                      color: NotionTheme.background,
                      border: Border(
                        top: BorderSide(color: NotionTheme.divider),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          const SnackCharacterIllustration(height: 52),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  state.isSubmitting ||
                                      state.selectedSnackIds.isEmpty
                                  ? null
                                  : () {
                                      _homeBloc.add(SubmitOrder());
                                    },
                              child: state.isSubmitting
                                  ? const FoodLoaderInline(size: 18)
                                  : Text(
                                      _hasSameSnackSelection(
                                            state.todaysOrders,
                                            state.selectedSnackIds,
                                          )
                                          ? 'Keep Current Order'
                                          : 'Confirm Order',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  bool _hasSameSnackSelection(
    List<LocalOrder> todaysOrders,
    List<String> selectedSnackIds,
  ) {
    if (todaysOrders.length != selectedSnackIds.length) return false;
    final existingIds = todaysOrders.map((order) => order.snackId).toSet();
    return existingIds.length == selectedSnackIds.toSet().length &&
        existingIds.containsAll(selectedSnackIds);
  }

  List<String> _buildCategoryOptions(List<LocalSnack> snacks) {
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
    return ['All', 'Drinks', ...categories];
  }

  bool _hasCutoffPassed(String cutoffTime) {
    final parts = cutoffTime.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;

    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day, hour, minute);
    return now.isAfter(cutoff);
  }

  String _formatCutoffTime(String cutoffTime) {
    final parts = cutoffTime.split(':');
    if (parts.length != 2) return '12:00 PM';
    final hour = int.tryParse(parts[0]) ?? 12;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  Widget _buildSnackList(List<LocalSnack> snacks, HomeLoaded state) {
    if (snacks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final snack in snacks)
          _buildSnackCard(snack, state.selectedSnackIds.contains(snack.id)),
      ],
    );
  }

  Widget _buildCategoryContent(
    HomeLoaded state,
    List<LocalSnack> filteredSnacks,
    String selectedCategory,
    bool isCutoffClosed,
  ) {
    if (isCutoffClosed) {
      if (selectedCategory == 'Drinks') {
        return _buildDrinksClosedCard(state);
      }
      if (selectedCategory == 'All') {
        return Column(
          children: [
            _buildCutoffClosedCard(state),
            const SizedBox(height: 20),
            _buildDrinksSection(state, showTitle: true),
          ],
        );
      }
      return _buildCutoffClosedCard(state);
    }

    if (selectedCategory == 'Drinks') {
      return _buildDrinksSection(state, showTitle: false);
    }

    if (selectedCategory == 'All') {
      return Column(
        children: [
          _buildSnackList(filteredSnacks, state),
          const SizedBox(height: 20),
          _buildDrinksSection(state, showTitle: true),
        ],
      );
    }

    return _buildSnackList(filteredSnacks, state);
  }

  Widget _buildCategoryScroller(
    List<String> categories,
    String selectedCategory,
  ) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 78,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? NotionTheme.surfaceSelected
                          : NotionTheme.surfaceHover,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? NotionTheme.primaryText
                            : NotionTheme.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      snackCategoryIcon(category),
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        category,
                        maxLines: 2,
                        softWrap: true,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.15,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? NotionTheme.primaryText
                              : NotionTheme.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? NotionTheme.primaryText
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final state = context.read<HomeBloc>().state;
    String cutoffLabel = '12:00 PM';
    var isCutoffClosed = false;
    if (state is HomeLoaded) {
      isCutoffClosed = _hasCutoffPassed(state.cutoffTime);
      cutoffLabel = _formatCutoffTime(state.cutoffTime);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NotionTheme.surfaceSelected,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: NotionTheme.blueAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: NotionTheme.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCutoffClosed
                      ? 'Ordering closed at $cutoffLabel'
                      : 'Order window closes at $cutoffLabel',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  isCutoffClosed
                      ? 'Come back tomorrow for the next snack window'
                      : 'Choose your snacks before the cutoff time',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCutoffClosedCard(HomeLoaded state) {
    final snackNamesById = {
      for (final snack in state.snacks) snack.id: snack.name,
    };
    final orderedNames = state.todaysOrders
        .map((order) => snackNamesById[order.snackId])
        .whereType<String>()
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NotionTheme.surfaceHover,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NotionTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: NotionTheme.surfaceSelected,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timer_off_outlined,
                  color: NotionTheme.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Snack ordering is closed for today',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The cutoff time of ${_formatCutoffTime(state.cutoffTime)} has passed.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NotionTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (orderedNames.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NotionTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NotionTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your selection',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    orderedNames.join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: NotionTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVegModeToggle(bool isVegMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VEG',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'MODE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Switch(
          value: isVegMode,
          activeThumbColor: NotionTheme.background,
          activeTrackColor: NotionTheme.greenAccent,
          inactiveThumbColor: NotionTheme.background,
          inactiveTrackColor: NotionTheme.secondaryText.withValues(alpha: 0.35),
          onChanged: (value) {
            _homeBloc.add(ChangeFilter(value ? 'Veg' : 'All'));
          },
        ),
      ],
    );
  }

  Widget _buildSnackCard(LocalSnack snack, bool isSelected) {
    final accent = snack.isVeg
        ? NotionTheme.greenAccent
        : NotionTheme.redAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          _homeBloc.add(ToggleSnack(snack.id));
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? NotionTheme.surfaceSelected
                : NotionTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? NotionTheme.primaryText : NotionTheme.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snack.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            snack.isVeg ? 'VEG' : 'N-VEG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: NotionTheme.surfaceHover,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            snack.servingSize ?? '1 Unit',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snack.description ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NotionTheme.secondaryText,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 116,
                child: SizedBox(
                  height: 122,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: NotionTheme.surfaceHover,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: NotionTheme.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          snack.emoji ?? '🍽️',
                          style: const TextStyle(fontSize: 46),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? NotionTheme.primaryText
                                : NotionTheme.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? NotionTheme.primaryText
                                  : NotionTheme.border,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isSelected ? 'ADDED' : 'ADD',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? NotionTheme.background
                                          : NotionTheme.primaryText,
                                    ),
                              ),
                              if (!isSelected) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.add,
                                  size: 16,
                                  color: NotionTheme.primaryText,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrinksSection(HomeLoaded state, {required bool showTitle}) {
    final isCutoffClosed = _hasCutoffPassed(state.cutoffTime);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'Drinks',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isCutoffClosed
                ? 'Drink selection is closed for today.'
                : 'Choose your drink for today.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
        if (isCutoffClosed)
          _buildDrinksClosedCard(state)
        else if (state.drinks.isEmpty)
          const Center(child: FoodLoader(size: 28))
        else
          Column(
            children: [
              for (final drink in state.drinks)
                _buildDrinkCard(drink, state.selectedDrinkId == drink['id']),
            ],
          ),
      ],
    );
  }

  Widget _buildDrinksClosedCard(HomeLoaded state) {
    final selectedDrink = state.drinks.cast<Map<String, dynamic>?>().firstWhere(
      (drink) => drink?['id'] == state.selectedDrinkId,
      orElse: () => null,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NotionTheme.surfaceHover,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NotionTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drink selection closed',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'The cutoff time of ${_formatCutoffTime(state.cutoffTime)} has passed.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: NotionTheme.secondaryText),
          ),
          if (selectedDrink != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: NotionTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NotionTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedDrink['emoji'] as String? ?? '🥤',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Selected drink: ${selectedDrink['name'] as String? ?? 'Saved'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrinkCard(Map<String, dynamic> drink, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _homeBloc.add(SelectDrink(drink['id'] as String)),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? NotionTheme.surfaceSelected
                : NotionTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? NotionTheme.primaryText : NotionTheme.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drink['name'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: NotionTheme.surfaceHover,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Drink',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Served along with your order.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NotionTheme.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 116,
                child: SizedBox(
                  height: 122,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: NotionTheme.surfaceHover,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: NotionTheme.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          drink['emoji'] as String? ?? '🥤',
                          style: const TextStyle(fontSize: 46),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? NotionTheme.primaryText
                                : NotionTheme.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? NotionTheme.primaryText
                                  : NotionTheme.border,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isSelected ? 'ADDED' : 'ADD',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? NotionTheme.background
                                          : NotionTheme.primaryText,
                                    ),
                              ),
                              if (!isSelected) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.add,
                                  size: 16,
                                  color: NotionTheme.primaryText,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuHeader(HomeLoaded state) {
    final isVegMode = state.filter == 'Veg';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Menu',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _hasCutoffPassed(state.cutoffTime)
                    ? 'Ordering is closed for today'
                    : isVegMode
                    ? 'Showing only vegetarian snacks'
                    : 'Select snacks and drinks for today',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (!_hasCutoffPassed(state.cutoffTime)) _buildVegModeToggle(isVegMode),
      ],
    );
  }
}
