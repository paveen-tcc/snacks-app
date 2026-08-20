import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/di/locator.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/repositories/admin_repository.dart';

class SummaryScreen extends StatefulWidget {
  final bool isTab;
  final bool isActive;
  const SummaryScreen({super.key, this.isTab = false, this.isActive = false});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _loading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SummaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = await locator<AdminRepository>().getSummary();
      if (mounted) {
        setState(() { _data = data; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendWhatsApp() async {
    if (_data == null) return;
    final orders = List<Map<String, dynamic>>.from(_data!['orders']);
    final drinks = List<Map<String, dynamic>>.from(_data!['drinks']);
    final date = _data!['date'] as String;

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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp is not available on this device')),
      );
    }
  }

  /// Collapses repeated usernames (one row per ordered unit) into a single
  /// entry with a `×n` suffix when a person ordered more than one, e.g.
  /// `Dhileep A ×3`. First-seen order is preserved.
  String _formatUsers(List<String> users) {
    final counts = <String, int>{};
    final order = <String>[];
    for (final user in users) {
      if (!counts.containsKey(user)) order.add(user);
      counts[user] = (counts[user] ?? 0) + 1;
    }
    return order
        .map((user) => counts[user]! > 1 ? '$user ×${counts[user]}' : user)
        .join(', ');
  }

  String _formatWhatsAppDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    return '${parts[2]} - ${parts[1]} - ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = _loading
        ? ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: const [FoodListSkeleton(count: 3)],
          )
        : _data == null
        ? const Center(child: Text('Failed to load summary'))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                120,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildNotOrderedSection(context),
                const SizedBox(height: AppSpacing.xxl),
                () {
                  final orders = List<Map<String, dynamic>>.from(_data!['orders']);
                  final totalOrders = _data!['totalOrders']?.toString() ?? '0';
                  return _buildSection(context, 'Snack Orders', [
                    if (orders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'No snack orders yet',
                          style: context.text.bodySmall?.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                      )
                    else ...[
                      ...orders.map(
                        (o) => _buildCountRow(
                          context,
                          o['snackName'] as String? ?? 'Unknown',
                          o['count'].toString(),
                          users: List<String>.from(o['orderedBy'] ?? []),
                        ),
                      ),
                      Divider(height: 1, color: context.palette.divider),
                      _buildCountRow(
                        context,
                        'Total',
                        totalOrders,
                        bold: true,
                      ),
                    ],
                  ]);
                }(),
                const SizedBox(height: AppSpacing.xxl),
                () {
                  final drinks = List<Map<String, dynamic>>.from(_data!['drinks']);
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
                            color: context.palette.textSecondary,
                          ),
                        ),
                      )
                    else ...[
                      ...drinks.map(
                        (d) => _buildCountRow(
                          context,
                          d['drinkName'] as String? ?? 'Unknown',
                          d['count'].toString(),
                          users: List<String>.from(d['votedBy'] ?? []),
                        ),
                      ),
                      Divider(height: 1, color: context.palette.divider),
                      _buildCountRow(
                        context,
                        'Total',
                        totalDrinks.toString(),
                        bold: true,
                      ),
                    ],
                  ]);
                }(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );

    final whatsappAction = _data != null
        ? _WhatsAppButton(onPressed: _sendWhatsApp)
        : null;

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

  Widget _buildNotOrderedSection(BuildContext context) {
    final palette = context.palette;
    final notOrdered = List<String>.from(_data!['notOrdered'] ?? const []);
    return _buildSection(context, 'Not Ordered (${notOrdered.length})', [
      if (notOrdered.isEmpty)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Everyone has ordered 🎉',
            style: context.text.bodySmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Text(
            notOrdered.join(', '),
            style: context.text.bodyMedium,
          ),
        ),
    ]);
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
    List<String> users = const [],
    bool bold = false,
  }) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                count,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (users.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _formatUsers(users),
              style: context.text.bodySmall?.copyWith(
                color: palette.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ],
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
