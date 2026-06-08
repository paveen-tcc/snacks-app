import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/di/locator.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/repositories/admin_repository.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

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

  Future<void> _load() async {
    try {
      final data = await locator<AdminRepository>().getSummary();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
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
      final maxVotes = drinks
          .map((drink) => (drink['count'] as num?)?.toInt() ?? 0)
          .fold<int>(0, (maxValue, count) => count > maxValue ? count : maxValue);
      final topDrinks = drinks
          .where((drink) => ((drink['count'] as num?)?.toInt() ?? 0) == maxVotes)
          .toList();
      for (final d in topDrinks) {
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

  String _formatWhatsAppDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    return '${parts[2]} - ${parts[1]} - ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: "Today's Summary"),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: const [FoodListSkeleton(count: 3)],
            )
          : _data == null
          ? const Center(child: Text('Failed to load summary'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: [
                Text(
                  'Date: ${_data!['date']}',
                  style: context.text.bodySmall?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(context, 'Snack Orders', [
                  ...List<Map<String, dynamic>>.from(_data!['orders']).map(
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
                    _data!['totalOrders'].toString(),
                    bold: true,
                  ),
                ]),
                const SizedBox(height: AppSpacing.xxl),
                _buildSection(context, 'Hot Drink Poll', [
                  ...List<Map<String, dynamic>>.from(_data!['drinks']).map(
                    (d) => _buildCountRow(
                      context,
                      d['drinkName'] as String? ?? 'Unknown',
                      d['count'].toString(),
                      users: List<String>.from(d['votedBy'] ?? []),
                    ),
                  ),
                  if ((_data!['drinks'] as List).isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'No votes yet',
                        style: context.text.bodySmall?.copyWith(
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: AppSpacing.x3),
                PrimaryButton(
                  label: 'Send to WhatsApp',
                  icon: Icons.chat_rounded,
                  onPressed: _sendWhatsApp,
                ),
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
              users.join(', '),
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
