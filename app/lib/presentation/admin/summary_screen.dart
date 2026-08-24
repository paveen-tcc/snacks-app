import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/food_assets.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/glass.dart';
import '../../core/di/locator.dart';
import '../../core/formatters/rupees.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/repositories/admin_repository.dart';

class SummaryScreen extends StatefulWidget {
  final bool isTab;
  final bool isActive;
  final DateTime? initialDate;

  const SummaryScreen({
    super.key,
    this.isTab = false,
    this.isActive = false,
    this.initialDate,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  static const _shortMonths = [
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
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late DateTime _selectedDate;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>>? _catalogSnacks;
  List<Map<String, dynamic>>? _allUsers;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _load();
  }

  @override
  void didUpdateWidget(covariant SummaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load();
    }
  }

  String get _isoDate =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = _weekdays[_selectedDate.weekday - 1];
    final month = _shortMonths[_selectedDate.month - 1];
    final day = _selectedDate.day;

    if (_selectedDate == today) {
      return 'Today, $month $day';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (_selectedDate == yesterday) {
      return 'Yesterday, $month $day';
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (_selectedDate == tomorrow) {
      return 'Tomorrow, $month $day';
    }
    return '$weekday, $month $day';
  }

  Map<String, String> get _usernameToIdMap {
    final map = <String, String>{};
    if (_allUsers != null) {
      for (final u in _allUsers!) {
        final id = u['id'] as String?;
        final name = u['username'] as String?;
        if (id != null && name != null && id.isNotEmpty) {
          map[name.toLowerCase().trim()] = id;
        }
      }
    }
    return map;
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner && _data == null && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final repo = locator<AdminRepository>();
      final summaryRes = await repo.getSummary(date: _isoDate);
      List<Map<String, dynamic>>? catalogRes = _catalogSnacks;
      if (catalogRes == null) {
        final rawCatalog = await repo.getAllSnacks();
        catalogRes = List<Map<String, dynamic>>.from(
          rawCatalog.map((e) => Map<String, dynamic>.from(e)),
        );
      }
      List<Map<String, dynamic>>? usersRes = _allUsers;
      if (usersRes == null) {
        try {
          final rawUsers = await repo.getUsers();
          usersRes = List<Map<String, dynamic>>.from(
            rawUsers.map((e) => Map<String, dynamic>.from(e)),
          );
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _data = Map<String, dynamic>.from(summaryRes);
          _catalogSnacks = catalogRes;
          _allUsers = usersRes;
          _loading = false;
          _error = null;
        });
      }
    } catch (e, st) {
      debugPrint('Summary load error: $e\n$st');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _load();
  }

  void _onNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _load();
  }

  Future<void> _onPickCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
      _load();
    }
  }

  Future<void> _sendWhatsApp() async {
    if (_data == null) return;
    final orders = List<Map<String, dynamic>>.from(_data!['orders'] ?? []);
    final drinks = List<Map<String, dynamic>>.from(_data!['drinks'] ?? []);
    final date = _data!['date'] as String? ?? _isoDate;

    final buf = StringBuffer();
    buf.writeln('Date: ${_formatWhatsAppDate(date)}');
    buf.writeln();
    buf.writeln('Drinks:');
    if (drinks.isNotEmpty) {
      final sortedDrinks = List<Map<String, dynamic>>.from(drinks)
        ..sort(
          (a, b) => ((b['count'] as num?)?.toInt() ?? 0)
              .compareTo((a['count'] as num?)?.toInt() ?? 0),
        );
      for (final d in sortedDrinks) {
        buf.writeln('${d['drinkName']} - ${d['count']}');
      }
    } else {
      buf.writeln('No votes yet');
    }
    buf.writeln();
    buf.writeln('Snacks:');
    if (orders.isNotEmpty) {
      for (final o in orders) {
        buf.writeln('${o['snackName']} - ${o['count']}');
      }
    } else {
      buf.writeln('No orders yet');
    }

    final message = buf.toString();
    final whatsappUri = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {'text': message},
    );
    final fallbackUri = Uri.https('wa.me', '/', {'text': message});

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      return;
    }
    _showMessage('WhatsApp is not available on this device');
  }

  String _formatWhatsAppDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    return '${parts[2]} - ${parts[1]} - ${parts[0]}';
  }

  // --- Item Reassignment Bottom Sheet ---
  Future<void> _openReassignSheet({
    required String snackId,
    required String snackName,
    required String? emoji,
    required bool isDrink,
    required List<Map<String, dynamic>> users,
    List<String> fallbackUsernames = const [],
  }) async {
    var catalog = _catalogSnacks ?? [];
    if (catalog.isEmpty) {
      try {
        final rawCatalog = await locator<AdminRepository>().getAllSnacks();
        catalog = List<Map<String, dynamic>>.from(
          rawCatalog.map((e) => Map<String, dynamic>.from(e)),
        );
        _catalogSnacks = catalog;
      } catch (_) {}
    }

    final resolvedUsers = <Map<String, dynamic>>[];
    final nameToId = _usernameToIdMap;
    if (users.isNotEmpty) {
      for (final u in users) {
        final username = u['username'] as String? ?? 'User';
        var id = u['id'] as String? ?? '';
        if (id.isEmpty) {
          id = nameToId[username.toLowerCase().trim()] ?? '';
        }
        resolvedUsers.add({'id': id, 'username': username});
      }
    } else if (fallbackUsernames.isNotEmpty) {
      for (final name in fallbackUsernames) {
        final id = nameToId[name.toLowerCase().trim()] ?? '';
        resolvedUsers.add({'id': id, 'username': name});
      }
    }

    final filteredCatalog = catalog.where((item) {
      final cat = (item['category'] as String? ?? '').toLowerCase();
      final itemIsDrink = cat == 'drinks';
      return isDrink ? itemIsDrink : !itemIsDrink;
    }).toList();

    if (!mounted) return;

    await showGlassBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _ReassignItemSheet(
        date: _isoDate,
        snackId: snackId,
        snackName: snackName,
        emoji: emoji,
        isDrink: isDrink,
        assignedUsers: resolvedUsers,
        catalog: filteredCatalog,
        onReassigned: (toSnackName) {
          _showMessage('Reassigned to $toSnackName and updated budget');
          _load(showSpinner: false);
        },
      ),
    );
  }

  // --- User Order Edit / Assignment Bottom Sheet ---
  Future<void> _openUserOrderSheet({
    required String userId,
    required String username,
    List<Map<String, dynamic>> initialOrders = const [],
  }) async {
    final repo = locator<AdminRepository>();
    var targetUserId = userId;
    if (targetUserId.isEmpty) {
      if (_allUsers == null || _allUsers!.isEmpty) {
        try {
          final uList = await repo.getUsers();
          _allUsers = List<Map<String, dynamic>>.from(uList);
        } catch (_) {}
      }
      final match = _allUsers?.firstWhere(
        (u) =>
            (u['username'] as String? ?? '').toLowerCase().trim() ==
            username.toLowerCase().trim(),
        orElse: () => <String, dynamic>{},
      );
      if (match != null && match.containsKey('id')) {
        targetUserId = match['id'] as String? ?? '';
      }
    }

    if (targetUserId.isEmpty) {
      _showMessage('Unable to find user record for $username');
      return;
    }

    var catalog = _catalogSnacks ?? [];
    if (catalog.isEmpty) {
      try {
        final rawCatalog = await repo.getAllSnacks();
        catalog = List<Map<String, dynamic>>.from(
          rawCatalog.map((e) => Map<String, dynamic>.from(e)),
        );
        _catalogSnacks = catalog;
      } catch (e) {
        _showMessage('Failed to load item catalog: $e');
        return;
      }
    }

    // Also populate any initial orders if not passed explicitly
    final resolvedInitialOrders =
        List<Map<String, dynamic>>.from(initialOrders);
    if (resolvedInitialOrders.isEmpty && _data != null) {
      final orders = List<Map<String, dynamic>>.from(_data!['orders'] ?? []);
      for (final o in orders) {
        final uList = List<Map<String, dynamic>>.from(o['users'] ?? []);
        final uNames = List<String>.from(o['orderedBy'] ?? []);
        final hasUser = uList.any(
              (u) => u['id'] == targetUserId || u['username'] == username,
            ) ||
            uNames.any(
              (name) =>
                  name.toLowerCase().trim() == username.toLowerCase().trim(),
            );
        if (hasUser) {
          resolvedInitialOrders.add({
            'snackId': o['snackId'],
            'name': o['snackName'],
            'isDrink': false,
          });
        }
      }
      final drinks = List<Map<String, dynamic>>.from(_data!['drinks'] ?? []);
      for (final d in drinks) {
        final uList = List<Map<String, dynamic>>.from(d['users'] ?? []);
        final uNames = List<String>.from(d['votedBy'] ?? []);
        final hasUser = uList.any(
              (u) => u['id'] == targetUserId || u['username'] == username,
            ) ||
            uNames.any(
              (name) =>
                  name.toLowerCase().trim() == username.toLowerCase().trim(),
            );
        if (hasUser) {
          resolvedInitialOrders.add({
            'snackId': d['drinkId'],
            'name': d['drinkName'],
            'isDrink': true,
          });
        }
      }
    }

    if (!mounted) return;

    await showGlassBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _UserOrderSheet(
        date: _isoDate,
        userId: targetUserId,
        username: username,
        catalog: catalog,
        initialOrders: resolvedInitialOrders,
        onSaved: () {
          _showMessage('Updated order for $username');
          _load(showSpinner: false);
        },
        onDeleted: () {
          _showMessage('Removed order for $username');
          _load(showSpinner: false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final whatsappAction = _data != null
        ? _WhatsAppButton(onPressed: _sendWhatsApp)
        : null;

    final bodyContent = Column(
      children: [
        _buildDateNavigator(context),
        Expanded(
          child: _loading && _data == null
              ? ListView(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  children: const [FoodListSkeleton(count: 3)],
                )
              : _error != null && _data == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Failed to load summary',
                        style: context.text.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _load(showSpinner: false),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.xs,
                      AppSpacing.page,
                      120,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildNotOrderedSection(context),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSnackOrdersSection(context),
                      const SizedBox(height: AppSpacing.xl),
                      _buildDrinkOrdersSection(context),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
        ),
      ],
    );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Summary',
                    style: context.text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ?whatsappAction,
                ],
              ),
            ),
            Expanded(child: bodyContent),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Summary',
        actions: [
          if (whatsappAction != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.page),
              child: Center(child: whatsappAction),
            ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildDateNavigator(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.page,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadii.rMd,
          border: Border.all(color: palette.border),
          boxShadow: context.shadows.sm,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              tooltip: 'Previous Day',
              onPressed: _onPreviousDay,
            ),
            Expanded(
              child: InkWell(
                borderRadius: AppRadii.rSm,
                onTap: _onPickCalendar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: palette.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _dateLabel,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              tooltip: 'Next Day',
              onPressed: _onNextDay,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotOrderedSection(BuildContext context) {
    final palette = context.palette;
    final notOrderedUsers = List<Map<String, dynamic>>.from(
      _data?['notOrderedUsers'] ?? [],
    );
    final fallbackList = List<String>.from(_data?['notOrdered'] ?? []);

    final resolvedNotOrdered = <Map<String, String>>[];
    final nameToId = _usernameToIdMap;

    if (notOrderedUsers.isNotEmpty) {
      for (final u in notOrderedUsers) {
        final username = u['username'] as String? ?? 'User';
        var id = u['id'] as String? ?? '';
        if (id.isEmpty) {
          id = nameToId[username.toLowerCase().trim()] ?? '';
        }
        resolvedNotOrdered.add({'id': id, 'username': username});
      }
    } else if (fallbackList.isNotEmpty) {
      for (final name in fallbackList) {
        final id = nameToId[name.toLowerCase().trim()] ?? '';
        resolvedNotOrdered.add({'id': id, 'username': name});
      }
    }

    return _buildSection(
      context,
      'Not Ordered (${resolvedNotOrdered.length})',
      [
        if (resolvedNotOrdered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Text('🎉 ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    'Everyone has ordered for this day!',
                    style: context.text.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap any user to assign them a snack or drink:',
                  style: context.text.bodySmall?.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: resolvedNotOrdered.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final u = entry.value;
                    final username = u['username'] ?? 'User';
                    final userId = u['id'] ?? '';
                    return ActionChip(
                      key: Key('not-ordered-$username-$idx'),
                      avatar: const Icon(Icons.add_rounded, size: 14),
                      label: Text(username),
                      labelStyle: context.text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: palette.surfaceMuted,
                      side: BorderSide(color: palette.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onPressed: () => _openUserOrderSheet(
                        userId: userId,
                        username: username,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSnackOrdersSection(BuildContext context) {
    final palette = context.palette;
    final orders = List<Map<String, dynamic>>.from(_data?['orders'] ?? []);
    final totalOrders = _data?['totalOrders']?.toString() ?? '0';

    return _buildSection(context, 'Snack Orders', [
      if (orders.isEmpty)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'No snack orders yet',
            style: context.text.bodySmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
        )
      else ...[
        for (final o in orders)
          _buildItemSummaryRow(
            context: context,
            snackId: o['snackId'] as String? ?? '',
            name: o['snackName'] as String? ?? 'Unknown',
            emoji: o['snackEmoji'] as String?,
            count: o['count']?.toString() ?? '0',
            priceRupees: (o['priceRupees'] as num?)?.toInt() ?? 0,
            isDrink: false,
            users: List<Map<String, dynamic>>.from(o['users'] ?? []),
            fallbackUsernames: List<String>.from(o['orderedBy'] ?? []),
          ),
        Divider(height: 1, color: palette.divider),
        _buildCountRow(
          context,
          'Total Snack Units',
          totalOrders,
          bold: true,
        ),
      ],
    ]);
  }

  Widget _buildDrinkOrdersSection(BuildContext context) {
    final palette = context.palette;
    final drinks = List<Map<String, dynamic>>.from(_data?['drinks'] ?? []);
    final totalDrinks = drinks.fold<int>(
      0,
      (sum, d) => sum + ((d['count'] as num?)?.toInt() ?? 0),
    );

    return _buildSection(context, 'Drink Orders', [
      if (drinks.isEmpty)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'No drink orders yet',
            style: context.text.bodySmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
        )
      else ...[
        for (final d in drinks)
          _buildItemSummaryRow(
            context: context,
            snackId: d['drinkId'] as String? ?? '',
            name: d['drinkName'] as String? ?? 'Unknown',
            emoji: d['drinkEmoji'] as String?,
            count: d['count']?.toString() ?? '0',
            priceRupees: (d['priceRupees'] as num?)?.toInt() ?? 0,
            isDrink: true,
            users: List<Map<String, dynamic>>.from(d['users'] ?? []),
            fallbackUsernames: List<String>.from(d['votedBy'] ?? []),
          ),
        Divider(height: 1, color: palette.divider),
        _buildCountRow(
          context,
          'Total Drinks',
          totalDrinks.toString(),
          bold: true,
        ),
      ],
    ]);
  }

  Widget _buildItemSummaryRow({
    required BuildContext context,
    required String snackId,
    required String name,
    required String? emoji,
    required String count,
    required int priceRupees,
    required bool isDrink,
    required List<Map<String, dynamic>> users,
    required List<String> fallbackUsernames,
  }) {
    final palette = context.palette;

    final resolvedUsers = <Map<String, String>>[];
    final nameToId = _usernameToIdMap;
    if (users.isNotEmpty) {
      for (final u in users) {
        final username = u['username'] as String? ?? 'User';
        var id = u['id'] as String? ?? '';
        if (id.isEmpty) {
          id = nameToId[username.toLowerCase().trim()] ?? '';
        }
        resolvedUsers.add({'id': id, 'username': username});
      }
    } else if (fallbackUsernames.isNotEmpty) {
      for (final name in fallbackUsernames) {
        final id = nameToId[name.toLowerCase().trim()] ?? '';
        resolvedUsers.add({'id': id, 'username': name});
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ItemThumbnail(
                name: name,
                emoji: emoji,
                isDrink: isDrink,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (priceRupees > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        formatRupees(priceRupees),
                        style: context.text.bodySmall?.copyWith(
                          color: palette.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadii.rSm,
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  '×$count',
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.brand,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                tooltip: 'Replace or reassign this item',
                color: palette.textSecondary,
                onPressed: () => _openReassignSheet(
                  snackId: snackId,
                  snackName: name,
                  emoji: emoji,
                  isDrink: isDrink,
                  users: users,
                  fallbackUsernames: fallbackUsernames,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (resolvedUsers.isNotEmpty) ...[
            Builder(
              builder: (context) {
                // Group users by unique user key (id or username) to show "Name ×count"
                final groupedUsers = <String, Map<String, dynamic>>{};
                for (final u in resolvedUsers) {
                  final username = u['username'] ?? 'User';
                  final userId = u['id'] ?? '';
                  final key =
                      userId.isNotEmpty ? userId : username.toLowerCase();
                  if (groupedUsers.containsKey(key)) {
                    groupedUsers[key]!['count'] =
                        (groupedUsers[key]!['count'] as int) + 1;
                  } else {
                    groupedUsers[key] = {
                      'id': userId,
                      'username': username,
                      'count': 1,
                    };
                  }
                }

                return Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: groupedUsers.values.map((u) {
                    final username = u['username'] as String;
                    final userId = u['id'] as String;
                    final userCount = u['count'] as int;
                    final labelText =
                        userCount > 1 ? '$username ×$userCount' : username;

                    return ActionChip(
                      key: Key('ordered-user-$username'),
                      label: Text(labelText),
                      labelStyle: context.text.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: palette.surface,
                      side: BorderSide(color: palette.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onPressed: () => _openUserOrderSheet(
                        userId: userId,
                        username: username,
                        initialOrders: [
                          {'snackId': snackId, 'name': name, 'isDrink': isDrink}
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: context.text.labelMedium?.copyWith(
              color: palette.textTertiary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: palette.border),
            borderRadius: AppRadii.rLg,
            boxShadow: context.shadows.sm,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildCountRow(
    BuildContext context,
    String label,
    String count, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            count,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Reassign Item Sheet ---
class _ReassignItemSheet extends StatefulWidget {
  final String date;
  final String snackId;
  final String snackName;
  final String? emoji;
  final bool isDrink;
  final List<Map<String, dynamic>> assignedUsers;
  final List<Map<String, dynamic>> catalog;
  final ValueChanged<String> onReassigned;

  const _ReassignItemSheet({
    required this.date,
    required this.snackId,
    required this.snackName,
    required this.emoji,
    required this.isDrink,
    required this.assignedUsers,
    required this.catalog,
    required this.onReassigned,
  });

  @override
  State<_ReassignItemSheet> createState() => _ReassignItemSheetState();
}

class _ReassignItemSheetState extends State<_ReassignItemSheet> {
  String? _selectedTargetSnackId;
  String? _selectedTargetName;
  bool _isSugarFree = false;
  late Set<String> _selectedUserIds;
  bool _saving = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedUserIds = widget.assignedUsers
        .map((u) => u['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> _submit() async {
    if (_selectedTargetSnackId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a replacement item')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await locator<AdminRepository>().reassignSummaryItem(
        date: widget.date,
        fromSnackId: widget.snackId.isNotEmpty ? widget.snackId : null,
        fromSnackName: widget.snackName,
        toSnackId: _selectedTargetSnackId!,
        isSugarFree: widget.isDrink ? _isSugarFree : null,
        userIds: _selectedUserIds.length == widget.assignedUsers.length
            ? null
            : _selectedUserIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReassigned(_selectedTargetName ?? 'replacement');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reassign: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = palette.isDark;
    final filtered = widget.catalog.where((item) {
      final name = (item['name'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Replace Item',
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Switch "${widget.snackName}" for another catalog item',
                        style: context.text.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // User Selection (if multiple users)
          if (widget.assignedUsers.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reassign for (${_selectedUserIds.length}/${widget.assignedUsers.length} users):',
                    style: context.text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedUserIds.length ==
                            widget.assignedUsers.length) {
                          _selectedUserIds.clear();
                        } else {
                          _selectedUserIds = widget.assignedUsers
                              .map((u) => u['id'] as String? ?? '')
                              .where((id) => id.isNotEmpty)
                              .toSet();
                        }
                      });
                    },
                    child: Text(
                      _selectedUserIds.length == widget.assignedUsers.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: widget.assignedUsers.map((u) {
                  final uId = u['id'] as String? ?? '';
                  final uName = u['username'] as String? ?? 'User';
                  final isSelected = _selectedUserIds.contains(uId);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(uName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedUserIds.add(uId);
                          } else {
                            _selectedUserIds.remove(uId);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search replacement ${widget.isDrink ? 'drink' : 'snack'}...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadii.rMd,
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          if (widget.isDrink) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Sugar Free Option'),
                value: _isSugarFree,
                onChanged: (val) => setState(() => _isSugarFree = val),
              ),
            ),
          ],

          // Catalog List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matching catalog items',
                      style: context.text.bodyMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      final id = item['id'] as String? ?? '';
                      final name = item['name'] as String? ?? '';
                      final emoji = item['emoji'] as String?;
                      final price = (item['priceRupees'] as num?)?.toInt() ?? 0;
                      final isSelected = _selectedTargetSnackId == id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.brand
                                  .withValues(alpha: isDark ? 0.2 : 0.08)
                              : palette.surfaceMuted,
                          borderRadius: AppRadii.rMd,
                          border: Border.all(
                            color: isSelected ? palette.brand : palette.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          leading: _ItemThumbnail(
                            name: name,
                            emoji: emoji,
                            isDrink: widget.isDrink,
                            size: 36,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: price > 0
                              ? Text(
                                  formatRupees(price),
                                  style: TextStyle(
                                    color: palette.textTertiary,
                                    fontSize: 11,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: palette.brand,
                                )
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.rMd,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedTargetSnackId = id;
                              _selectedTargetName = name;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: _saving ? 'Saving...' : 'Replace Item',
                    onPressed: _saving || _selectedTargetSnackId == null
                        ? null
                        : _submit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- User Order Sheet ---
class _UserOrderSheet extends StatefulWidget {
  final String date;
  final String userId;
  final String username;
  final List<Map<String, dynamic>> catalog;
  final List<Map<String, dynamic>> initialOrders;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;

  const _UserOrderSheet({
    required this.date,
    required this.userId,
    required this.username,
    required this.catalog,
    required this.initialOrders,
    required this.onSaved,
    required this.onDeleted,
  });

  @override
  State<_UserOrderSheet> createState() => _UserOrderSheetState();
}

class _UserOrderSheetState extends State<_UserOrderSheet> {
  String? _selectedSnackId;
  String? _selectedDrinkId;
  bool _isDrinkSugarFree = false;
  bool _saving = false;
  String _searchQuery = '';
  String _categoryFilter = 'all'; // 'all', 'snacks', 'drinks'

  @override
  void initState() {
    super.initState();
    for (final o in widget.initialOrders) {
      final isDrink = o['isDrink'] == true;
      final snackId = o['snackId'] as String?;
      final name = o['name'] as String? ?? '';
      if (isDrink) {
        _selectedDrinkId = snackId;
        if (name.toLowerCase().contains('(sugar free)')) {
          _isDrinkSugarFree = true;
        }
      } else {
        _selectedSnackId = snackId;
      }
    }
  }

  Future<void> _save() async {
    final snackIds = <String>[];
    final sugarFreeIds = <String>[];

    if (_selectedSnackId != null) snackIds.add(_selectedSnackId!);
    if (_selectedDrinkId != null) {
      snackIds.add(_selectedDrinkId!);
      if (_isDrinkSugarFree) sugarFreeIds.add(_selectedDrinkId!);
    }

    if (snackIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await locator<AdminRepository>().updateUserOrderAdmin(
        userId: widget.userId,
        date: widget.date,
        snackIds: snackIds,
        sugarFreeSnackIds: sugarFreeIds.isNotEmpty ? sugarFreeIds : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order: $e')),
        );
      }
    }
  }

  Future<void> _deleteOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Remove order for ${widget.username}?'),
        content: const Text('This will clear their order for this day.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await locator<AdminRepository>().deleteUserOrderAdmin(
        userId: widget.userId,
        date: widget.date,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onDeleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = palette.isDark;
    final hasInitialOrder = widget.initialOrders.isNotEmpty;
    final query = _searchQuery.trim().toLowerCase();

    final filtered = widget.catalog.where((item) {
      final cat = (item['category'] as String? ?? '').toLowerCase();
      final isDrink = cat == 'drinks';

      if (_categoryFilter == 'snacks' && isDrink) return false;
      if (_categoryFilter == 'drinks' && !isDrink) return false;

      if (query.isNotEmpty) {
        final name = (item['name'] as String? ?? '').toLowerCase();
        if (!name.contains(query)) return false;
      }
      return true;
    }).toList();

    // Selected item name helpers
    String? selectedSnackName;
    String? selectedDrinkName;
    if (_selectedSnackId != null) {
      final s = widget.catalog.firstWhere(
        (it) => it['id'] == _selectedSnackId,
        orElse: () => <String, dynamic>{},
      );
      selectedSnackName = s['name'] as String?;
    }
    if (_selectedDrinkId != null) {
      final d = widget.catalog.firstWhere(
        (it) => it['id'] == _selectedDrinkId,
        orElse: () => <String, dynamic>{},
      );
      selectedDrinkName = d['name'] as String?;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        children: [
          // Header matching "Your Order" modal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasInitialOrder
                            ? 'Edit Order: ${widget.username}'
                            : 'Add Item: ${widget.username}',
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select items from catalog for ${widget.username}',
                        style: context.text.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Active Selection Badges
          if (_selectedSnackId != null || _selectedDrinkId != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (selectedSnackName != null)
                          InputChip(
                            avatar:
                                const Icon(Icons.restaurant_rounded, size: 14),
                            label: Text(
                              selectedSnackName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: true,
                            showCheckmark: false,
                            deleteIcon:
                                const Icon(Icons.close_rounded, size: 14),
                            onDeleted: () =>
                                setState(() => _selectedSnackId = null),
                          ),
                        if (selectedDrinkName != null)
                          InputChip(
                            avatar:
                                const Icon(Icons.local_cafe_rounded, size: 14),
                            label: Text(
                              _isDrinkSugarFree
                                  ? '$selectedDrinkName (Sugar Free)'
                                  : selectedDrinkName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: true,
                            showCheckmark: false,
                            deleteIcon:
                                const Icon(Icons.close_rounded, size: 14),
                            onDeleted: () =>
                                setState(() => _selectedDrinkId = null),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedSnackId = null;
                      _selectedDrinkId = null;
                    }),
                    child:
                        const Text('Clear all', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search snacks and drinks...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadii.rMd,
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Category Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 4,
            ),
            child: Row(
              children: [
                _buildFilterTab(
                  label: 'All',
                  isSelected: _categoryFilter == 'all',
                  onTap: () => setState(() => _categoryFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  label: 'Snacks',
                  isSelected: _categoryFilter == 'snacks',
                  onTap: () => setState(() => _categoryFilter = 'snacks'),
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  label: 'Drinks',
                  isSelected: _categoryFilter == 'drinks',
                  onTap: () => setState(() => _categoryFilter = 'drinks'),
                ),
              ],
            ),
          ),

          // Sugar Free Option (when a drink is selected)
          if (_selectedDrinkId != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Sugar Free Option (for drink)'),
                value: _isDrinkSugarFree,
                onChanged: (val) => setState(() => _isDrinkSugarFree = val),
              ),
            ),
          ],

          // Catalog Items List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matching catalog items',
                      style: context.text.bodyMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      final id = item['id'] as String? ?? '';
                      final name = item['name'] as String? ?? '';
                      final emoji = item['emoji'] as String?;
                      final cat =
                          (item['category'] as String? ?? '').toLowerCase();
                      final isDrink = cat == 'drinks';
                      final price = (item['priceRupees'] as num?)?.toInt() ?? 0;
                      final isSelected = isDrink
                          ? (_selectedDrinkId == id)
                          : (_selectedSnackId == id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.brand
                                  .withValues(alpha: isDark ? 0.2 : 0.08)
                              : palette.surfaceMuted,
                          borderRadius: AppRadii.rMd,
                          border: Border.all(
                            color: isSelected ? palette.brand : palette.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          leading: _ItemThumbnail(
                            name: name,
                            emoji: emoji,
                            isDrink: isDrink,
                            size: 36,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: price > 0
                              ? Text(
                                  formatRupees(price),
                                  style: TextStyle(
                                    color: palette.textTertiary,
                                    fontSize: 11,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: palette.brand,
                                )
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.rMd,
                          ),
                          onTap: () {
                            setState(() {
                              if (isDrink) {
                                _selectedDrinkId =
                                    (_selectedDrinkId == id) ? null : id;
                              } else {
                                _selectedSnackId =
                                    (_selectedSnackId == id) ? null : id;
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                if (hasInitialOrder) ...[
                  IconButton.outlined(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    tooltip: 'Remove order',
                    onPressed: _saving ? null : _deleteOrder,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: _saving ? 'Saving...' : 'Save Order',
                    onPressed: _saving ||
                            (_selectedSnackId == null &&
                                _selectedDrinkId == null)
                        ? null
                        : _save,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? palette.brand : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? palette.brand : palette.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _WhatsAppButton extends StatelessWidget {
  const _WhatsAppButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF25D366),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_rounded,
                size: 14,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                'WhatsApp',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemThumbnail extends StatelessWidget {
  final String name;
  final String? emoji;
  final bool isDrink;
  final double size;

  const _ItemThumbnail({
    required this.name,
    this.emoji,
    required this.isDrink,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = localFoodAssetMap[name.toLowerCase().trim()];
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        ),
      );
    }

    if (emoji != null &&
        emoji!.isNotEmpty &&
        !emoji!.startsWith('http') &&
        !emoji!.startsWith('assets') &&
        emoji!.length <= 4) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            emoji!,
            style: TextStyle(fontSize: size * 0.6),
          ),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0x12000000),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: Text(
          isDrink ? '🥤' : '🍽️',
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }
}

