import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_settings.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/glass.dart';
import '../../core/di/locator.dart';
import '../../core/notifications/push_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../admin/holidays_screen.dart';
import '../admin/snacks_screen.dart';
import '../admin/users_screen.dart';
import '../home/bloc/home_bloc.dart';

/// Profile + settings, opened from the top-left profile icon.
/// Order: profile info → appearance → (admin) order settings → (admin) admin
/// links → sign out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.username,
    required this.isAdmin,
    required this.homeBloc,
  });

  final String username;
  final bool isAdmin;
  final HomeBloc homeBloc;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _settings = {};
  bool _loadingSettings = true;
  bool _sendingOrderReminder = false;

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) {
      _loadSettings();
    } else {
      _loadingSettings = false;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await locator<AdminRepository>().getSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _loadingSettings = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSettings = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await locator<AdminRepository>().updateSetting(key, value);
      await _loadSettings();
      widget.homeBloc.add(RefreshHome());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save')));
      }
    }
  }

  Future<void> _sendOrderReminder() async {
    if (_sendingOrderReminder) return;

    setState(() => _sendingOrderReminder = true);
    try {
      final result = await locator<AdminRepository>().sendOrderReminder();
      if (!mounted) return;

      final skippedReason = result['skippedReason'];
      final sent = result['sent'] is int ? result['sent'] as int : 0;
      final targeted = result['targeted'] is int
          ? result['targeted'] as int
          : 0;
      final message = skippedReason is String && skippedReason.isNotEmpty
          ? 'Reminder not sent: $skippedReason'
          : sent > 0
          ? 'Reminder sent to $sent device${sent == 1 ? '' : 's'}'
          : targeted == 0
          ? 'No pending users to remind'
          : 'Reminder sent';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reminder')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingOrderReminder = false);
    }
  }

  Future<void> _editTime(String key, String label, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 12,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: label,
    );
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await _updateSetting(key, value);
  }

  Future<void> _editText(String key, String label, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showAdaptiveDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter $label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result != current) _updateSetting(key, result);
  }

  Future<void> _signOut() async {
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign out',
              style: TextStyle(color: context.palette.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    // Stop reminders to this device for the user being signed out.
    await locator<PushService>().unregister();
    await locator<AuthRepository>().logout();
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final advanceOn = _settings['advance_order_mode'] == true;
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: const GlassAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _ProfileHeader(username: widget.username),
          const SizedBox(height: AppSpacing.xxl),

          _Section(
            title: 'Appearance',
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: AppSettings.darkMode,
                builder: (_, dark, _) => _ToggleTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark mode',
                  subtitle: 'Use the dark theme',
                  value: dark,
                  onChanged: AppSettings.setDarkMode,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: GlassCapability.reduceTransparency,
                builder: (_, reduce, _) => _ToggleTile(
                  icon: Icons.blur_on_rounded,
                  title: 'Reduce transparency',
                  subtitle: 'Disable the frosted-glass blur',
                  value: reduce,
                  onChanged: AppSettings.setReduceTransparency,
                ),
              ),
            ],
          ),

          if (widget.isAdmin) ...[
            const SizedBox(height: AppSpacing.xxl),
            _Section(
              title: 'Order settings',
              children: _loadingSettings
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                    ]
                  : [
                      _NavTile(
                        icon: Icons.timer_rounded,
                        title: 'Order cutoff time',
                        subtitle: _settings['cutoff_time'] ?? '12:00',
                        onTap: () => _editTime(
                          'cutoff_time',
                          'Cutoff time',
                          _settings['cutoff_time'] ?? '12:00',
                        ),
                      ),
                      _ToggleTile(
                        icon: Icons.event_available_rounded,
                        title: 'Advance order mode',
                        subtitle: 'Morning orders are placed for the next day',
                        value: advanceOn,
                        onChanged: (v) =>
                            _updateSetting('advance_order_mode', v),
                      ),
                      if (advanceOn)
                        _NavTile(
                          icon: Icons.schedule_rounded,
                          title: 'Advance window start',
                          subtitle:
                              _settings['advance_window_start'] ?? '06:00',
                          onTap: () => _editTime(
                            'advance_window_start',
                            'Window start',
                            _settings['advance_window_start'] ?? '06:00',
                          ),
                        ),
                      if (advanceOn)
                        _NavTile(
                          icon: Icons.schedule_rounded,
                          title: 'Advance window end',
                          subtitle: _settings['advance_window_end'] ?? '22:00',
                          onTap: () => _editTime(
                            'advance_window_end',
                            'Window end',
                            _settings['advance_window_end'] ?? '22:00',
                          ),
                        ),
                      _NavTile(
                        icon: Icons.public_rounded,
                        title: 'Holiday country code',
                        subtitle: _settings['holiday_country'] ?? 'IN',
                        onTap: () => _editText(
                          'holiday_country',
                          'Country code (e.g. IN, US)',
                          _settings['holiday_country'] ?? 'IN',
                        ),
                      ),
                      _NavTile(
                        icon: Icons.notifications_active_rounded,
                        title: 'Send order reminder',
                        subtitle: _sendingOrderReminder
                            ? 'Sending...'
                            : "Order now, it's closing",
                        enabled: !_sendingOrderReminder,
                        trailing: _sendingOrderReminder
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        onTap: _sendOrderReminder,
                      ),
                    ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _Section(
              title: 'Admin',
              children: [
                _NavTile(
                  icon: Icons.fastfood_rounded,
                  title: 'Manage snacks',
                  subtitle: 'Add, edit, toggle items',
                  onTap: () => _push(const AdminSnacksScreen()),
                ),
                _NavTile(
                  icon: Icons.event_busy_rounded,
                  title: 'Manage holidays',
                  subtitle: 'Shutdown days',
                  onTap: () => _push(const AdminHolidaysScreen()),
                ),
                _NavTile(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Manage users',
                  subtitle: 'Grant or revoke admin',
                  onTap: () => _push(const AdminUsersScreen()),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
          SecondaryButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            onPressed: _signOut,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((
      _,
    ) {
      if (widget.isAdmin) _loadSettings();
    });
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.username});
  final String username;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '🙂';
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: palette.brand.withValues(alpha: 0.14),
          child: Text(
            initial,
            style: context.text.displaySmall?.copyWith(color: palette.brand),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username.isNotEmpty ? username : 'Snacks account',
                style: context.text.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Your account',
                style: context.text.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(height: 1, color: palette.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      enabled: enabled,
      leading: Icon(
        icon,
        color: enabled ? palette.textSecondary : palette.textTertiary,
      ),
      title: Text(title, style: context.text.titleSmall),
      subtitle: Text(
        subtitle,
        style: context.text.bodySmall?.copyWith(color: palette.textSecondary),
      ),
      trailing:
          trailing ??
          Icon(Icons.chevron_right_rounded, color: palette.textTertiary),
      onTap: enabled ? onTap : null,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: Icon(icon, color: palette.textSecondary),
      title: Text(title, style: context.text.titleSmall),
      subtitle: Text(
        subtitle,
        style: context.text.bodySmall?.copyWith(color: palette.textSecondary),
      ),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}
