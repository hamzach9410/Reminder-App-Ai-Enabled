import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/reminder_model.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../core/constants/app_constants.dart';
import '../viewmodels/reminder_viewmodel.dart';

/// Premium Reminder detail Screen following NoteWise's clean, hero-driven design.
class ReminderDetailscreen extends StatelessWidget {
  final ReminderModel reminder;

  const ReminderDetailscreen({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = AppTheme.getPriorityColor(reminder.priority);
    final isActive = reminder.status == ReminderStatus.pending || reminder.status == ReminderStatus.snoozed;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
        ),
        actions: [
          IconButton(
            onPressed: () => _deleteReminder(context),
            icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 20),
          
          // Hero Category & Title
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  reminder.category.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            reminder.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 48),

          // Metadata Grid/List
          _buildInfoTile(
            context,
            icon: Icons.access_time_filled_rounded,
            title: 'SCHEDULED FOR',
            value: DateTimeUtils.getRelativeDateString(reminder.dateTime) + ' at ' + DateTimeUtils.formatTime(reminder.dateTime),
          ),
          const SizedBox(height: 16),
          _buildInfoTile(
            context,
            icon: Icons.flag_rounded,
            title: 'PRIORITY LEVEL',
            value: reminder.priority.displayName.toUpperCase(),
            valueColor: priorityColor,
          ),
          const SizedBox(height: 16),
          _buildInfoTile(
            context,
            icon: Icons.repeat_rounded,
            title: 'RECURRENCE',
            value: reminder.recurrence.displayName.toUpperCase(),
          ),
          const SizedBox(height: 16),
          _buildInfoTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'CURRENT STATUS',
            value: reminder.status.displayName.toUpperCase(),
            valueColor: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
          ),

          const SizedBox(height: 60),

          // Action Buttons
          if (isActive) ...[
            _PremiumActionButton(
              label: 'COMPLETE REMINDER',
              onPressed: () => _completeReminder(context),
              isPrimary: true,
            ),
            const SizedBox(height: 12),
            _PremiumActionButton(
              label: 'SNOOZE FOR ${AppConstants.snoozeMinutes} MIN',
              onPressed: () => _snoozeReminder(context),
              isPrimary: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeReminder(BuildContext context) async {
    final viewModel = context.read<ReminderViewModel>();
    final success = await viewModel.completeReminder(reminder.id);
    if (success && context.mounted) Navigator.pop(context);
  }

  Future<void> _snoozeReminder(BuildContext context) async {
    final viewModel = context.read<ReminderViewModel>();
    final success = await viewModel.snoozeReminder(reminder.id);
    if (success && context.mounted) Navigator.pop(context);
  }

  Future<void> _deleteReminder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final viewModel = context.read<ReminderViewModel>();
      final success = await viewModel.deleteReminder(reminder.id);
      if (success && context.mounted) Navigator.pop(context);
    }
  }
}

class _PremiumActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _PremiumActionButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? theme.colorScheme.primary : theme.colorScheme.surface,
          foregroundColor: isPrimary ? Colors.white : theme.colorScheme.primary,
          elevation: isPrimary ? 8 : 0,
          shadowColor: theme.colorScheme.primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isPrimary ? BorderSide.none : BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
