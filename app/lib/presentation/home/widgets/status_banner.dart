import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../bloc/home_bloc.dart';
import '../home_helpers.dart';

/// Compact live countdown banner for order cutoff window.
class HomeStatusBanner extends StatefulWidget {
  const HomeStatusBanner({super.key, required this.state});
  final HomeLoaded state;

  @override
  State<HomeStatusBanner> createState() => _HomeStatusBannerState();
}

class _HomeStatusBannerState extends State<HomeStatusBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant HomeStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.cutoffTime != widget.state.cutoffTime ||
        oldWidget.state.advanceWindowEnd != widget.state.advanceWindowEnd ||
        oldWidget.state.advanceOrderMode != widget.state.advanceOrderMode) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (!isOrderingClosed(widget.state)) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          if (isOrderingClosed(widget.state)) {
            _timer?.cancel();
          }
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration? _getTimeRemaining() {
    final state = widget.state;
    final timeStr =
        state.advanceOrderMode ? state.advanceWindowEnd : state.cutoffTime;
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day, hour, minute);
    final diff = cutoff.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  String _formatCountdown(Duration diff) {
    if (diff == Duration.zero) return 'Closed';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s left';
    } else {
      return '${seconds}s left';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final closed = isOrderingClosed(state);
    final closeTime = formatOrderWindowCloseTime(state);
    final isAdvance = state.advanceOrderMode && !closed;

    final tone = isAdvance
        ? StatusTone.warning
        : closed
        ? StatusTone.neutral
        : StatusTone.info;
    final icon = isAdvance
        ? Icons.event_available_rounded
        : closed
        ? Icons.timer_off_rounded
        : Icons.schedule_rounded;

    final diff = _getTimeRemaining();
    final countdownStr =
        diff != null && !closed && diff > Duration.zero
            ? ' • ${_formatCountdown(diff)}'
            : '';

    final title = isAdvance
        ? 'Advance Order • Closes at $closeTime$countdownStr'
        : closed
        ? 'Order window closed at $closeTime'
        : 'Order before $closeTime$countdownStr';

    return StatusBanner(
      tone: tone,
      icon: icon,
      title: title,
    );
  }
}
