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
  final Map<String, bool> _expandedCategories = {};

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

          final displayedSnacks = state.snacks.where((s) {
            if (state.filter == 'Veg') return s.isVeg == true;
            if (state.filter == 'Non-Veg') return s.isVeg == false;
            return true;
          }).toList();
          final groupedSnacks = _groupSnacksByCategory(displayedSnacks);

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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Today\'s Menu',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Select one or more snacks',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildFilterChips(state.filter),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          sliver: SliverToBoxAdapter(
                            child: _buildSnackSections(groupedSnacks, state),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: _buildHotDrinkPoll(context, state),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
            bottomNavigationBar: state.isShutdown
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

  List<MapEntry<String, List<LocalSnack>>> _groupSnacksByCategory(
    List<LocalSnack> snacks,
  ) {
    final grouped = <String, List<LocalSnack>>{};
    for (final snack in snacks) {
      final category = displaySnackCategory(snack.category);
      grouped.putIfAbsent(category, () => []).add(snack);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final rankCompare = snackCategoryRank(
          a.key,
        ).compareTo(snackCategoryRank(b.key));
        if (rankCompare != 0) return rankCompare;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    return entries;
  }

  bool _isCategoryExpanded(String category, int index) {
    return _expandedCategories[category] ?? index == 0;
  }

  Widget _buildSnackSections(
    List<MapEntry<String, List<LocalSnack>>> groupedSnacks,
    HomeLoaded state,
  ) {
    if (groupedSnacks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groupedSnacks.asMap().entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedCategories[entry.value.key] =
                          !_isCategoryExpanded(entry.value.key, entry.key);
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: NotionTheme.surfaceHover,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NotionTheme.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value.key,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NotionTheme.surfaceSelected,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${entry.value.value.length}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          _isCategoryExpanded(entry.value.key, entry.key)
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: NotionTheme.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        for (final snack in entry.value.value)
                          _buildSnackCard(
                            snack,
                            state.selectedSnackIds.contains(snack.id),
                          ),
                      ],
                    ),
                  ),
                  crossFadeState:
                      _isCategoryExpanded(entry.value.key, entry.key)
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final state = context.read<HomeBloc>().state;
    String defaultLabel = 'No default set';
    String cutoffLabel = '12:00 PM';
    if (state is HomeLoaded) {
      try {
        final defaultSnack = state.snacks.firstWhere((s) => s.isDefault);
        defaultLabel =
            'Default: ${defaultSnack.name} (${defaultSnack.servingSize ?? '1 Unit'})';
      } catch (_) {}
      // Format cutoff time (e.g. "12:00" -> "12:00 PM", "14:30" -> "2:30 PM")
      final parts = state.cutoffTime.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 12;
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        cutoffLabel = '$displayHour:$minute $period';
      }
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
                  'Order window closes at $cutoffLabel',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  defaultLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(String currentFilter) {
    return Wrap(
      spacing: 6,
      children: ['All', 'Veg', 'Non-Veg'].map((filter) {
        final isSelected = currentFilter == filter;
        return ChoiceChip(
          label: Text(
            filter,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? NotionTheme.background
                  : NotionTheme.primaryText,
            ),
          ),
          selected: isSelected,
          selectedColor: NotionTheme.primaryText,
          backgroundColor: NotionTheme.surfaceHover,
          showCheckmark: false,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide.none,
          ),
          onSelected: (selected) {
            if (selected) _homeBloc.add(ChangeFilter(filter));
          },
        );
      }).toList(),
    );
  }

  Widget _buildSnackCard(LocalSnack snack, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          _homeBloc.add(ToggleSnack(snack.id));
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? NotionTheme.surfaceHover
                : NotionTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? NotionTheme.primaryText : NotionTheme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(snack.emoji ?? '🍽️', style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            snack.name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: snack.isVeg
                                ? NotionTheme.greenAccent.withValues(alpha: 0.1)
                                : NotionTheme.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            snack.isVeg ? 'VEG' : 'N-VEG',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: snack.isVeg
                                  ? NotionTheme.greenAccent
                                  : NotionTheme.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snack.description ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: NotionTheme.surfaceHover,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  snack.servingSize ?? '1 Unit',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? NotionTheme.blueAccent
                    : NotionTheme.secondaryText.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotDrinkPoll(BuildContext context, HomeLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hot Drink Poll',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Vote for today\'s hot drink. Resets daily.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (state.drinks.isEmpty)
          const Center(child: FoodLoader(size: 28))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < state.drinks.length; i++)
                SizedBox(
                  width:
                      (MediaQuery.of(context).size.width -
                          32 -
                          (state.drinks.length - 1) * 10) /
                      state.drinks.length,
                  child: _buildPollOption(
                    state.drinks[i],
                    state.selectedDrinkId == state.drinks[i]['id'],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildPollOption(Map<String, dynamic> drink, bool isSelected) {
    return InkWell(
      onTap: () => _homeBloc.add(SelectDrink(drink['id'] as String)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? NotionTheme.surfaceSelected
              : NotionTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? NotionTheme.blueAccent.withValues(alpha: 0.5)
                : NotionTheme.border,
          ),
        ),
        child: Column(
          children: [
            Text(drink['emoji'] ?? '☕', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              drink['name'] as String,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? NotionTheme.blueAccent
                    : NotionTheme.primaryText,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              const Icon(
                Icons.check_circle,
                size: 14,
                color: NotionTheme.blueAccent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
