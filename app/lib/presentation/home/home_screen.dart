import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/notion_theme.dart';
import '../../core/widgets/illustrations.dart';
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

  @override
  void initState() {
    super.initState();
    _homeBloc = HomeBloc();
    _loadUsername();
  }

  bool _isAdmin = false;

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    final isAdmin = prefs.getBool('is_admin') ?? false;
    if (mounted) setState(() { _username = username; _isAdmin = isAdmin; });
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
            return const Scaffold(
              body: Center(child: FoodLoader()),
            );
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

          return Scaffold(
            appBar: AppBar(
              title: Text('Hello, ${_username.isNotEmpty ? _username : 'there'} 👋'),
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
            body: CustomScrollView(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Today\'s Menu',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
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
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final snack = displayedSnacks[index];
                      final isSelected = state.selectedSnackId == snack.id;
                      return _buildSnackCard(snack, isSelected);
                    }, childCount: displayedSnacks.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildHotDrinkPoll(context, state),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
            bottomNavigationBar: Container(
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
                        onPressed: state.isSubmitting
                            ? null
                            : () {
                                _homeBloc.add(SubmitOrder());
                              },
                        child: state.isSubmitting
                            ? const FoodLoaderInline(size: 18)
                            : Text(
                                state.todaysOrder != null &&
                                        state.todaysOrder?.snackId ==
                                            state.selectedSnackId
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

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NotionTheme.surfaceSelected,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NotionTheme.blueAccent.withValues(alpha: 0.3)),
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
                  'Order window closes at 12:00 PM',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Default: Samosa (2 Pcs)',
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
          _homeBloc.add(SelectSnack(snack.id));
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                  width: (MediaQuery.of(context).size.width - 32 - (state.drinks.length - 1) * 10) / state.drinks.length,
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
          color: isSelected ? NotionTheme.surfaceSelected : NotionTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? NotionTheme.blueAccent.withValues(alpha: 0.5) : NotionTheme.border,
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
                color: isSelected ? NotionTheme.blueAccent : NotionTheme.primaryText,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle, size: 14, color: NotionTheme.blueAccent),
            ],
          ],
        ),
      ),
    );
  }

}
