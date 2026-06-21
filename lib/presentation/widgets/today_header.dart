import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/utils/date_time_utils.dart';
import '../../data/models/reminder_model.dart';
import '../../core/constants/enums.dart';

/// Premium header widget following NoteWise design language.
/// Uses uppercase tracking, bold typography, and rounded-24 Containers.
/// Now features a live 'Ticker' for the next upcoming event.
class TodayHeader extends StatefulWidget {
  final ReminderModel? nextReminder;

  const TodayHeader({
    super.key,
    required this.nextReminder,
  });

  @override
  State<TodayHeader> createState() => _TodayHeaderState();
}

class _TodayHeaderState extends State<TodayHeader> {
  Timer? _ticker;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didUpdateWidget(TodayHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nextReminder != oldWidget.nextReminder) {
      _calculateTimeRemaining();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateTimeRemaining();
    });
    _calculateTimeRemaining();
  }

  void _calculateTimeRemaining() {
    if (widget.nextReminder == null) {
      if (mounted) setState(() => _timeRemaining = '');
      return;
    }

    final now = DateTime.now();
    final effectiveTime = widget.nextReminder!.snoozedUntil ?? widget.nextReminder!.dateTime;
    
    if (effectiveTime.isBefore(now)) {
      if (mounted) setState(() => _timeRemaining = 'dashboard.overdue'.tr().toUpperCase());
      return;
    }

    final diff = effectiveTime.difference(now);
    
    String formatted;
    if (diff.inHours > 0) {
      formatted = '${diff.inHours}h ${diff.inMinutes % 60}m ${diff.inSeconds % 60}s';
    } else if (diff.inMinutes > 0) {
      formatted = '${diff.inMinutes}m ${diff.inSeconds % 60}s';
    } else {
      formatted = '${diff.inSeconds}s';
    }

    if (mounted) {
      setState(() {
        _timeRemaining = '${'dashboard.starts_in'.tr().toUpperCase()} $formatted';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dashboard.today'.tr().toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM d, yyyy').format(now),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'dashboard.next_reminder'.tr().toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildNextCard(context),
        ),
      ],
    );
  }

  Widget _buildNextCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.nextReminder == null) {
      return Container(
        key: const ValueKey('no_next'),
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 32,
                color: theme.colorScheme.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vault SECURED'.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    final effectiveTime = widget.nextReminder!.snoozedUntil ?? widget.nextReminder!.dateTime;
    
    return Container(
      key: ValueKey('next_${widget.nextReminder!.id}'),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.5), // Stronger Indigo Glow
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Saturated System Gradient
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7C3AED), // Vibrant Violet
                    Color(0xFF4F46E5), // Indigo
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weight 900'.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'IMMINENT\nUNIT',
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 0.9,
                      color: Colors.white,
                      letterSpacing: -2.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

