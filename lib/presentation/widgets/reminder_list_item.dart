import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/reminder_model.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/constants/enums.dart';
import '../viewmodels/reminder_viewmodel.dart';

/// Premium List Item following NoteWise's clean "Vault" aesthetic.
/// Features rounded-24 Containers, premium category colors, and Overdue badges.
class ReminderListItem extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onTap;

  const ReminderListItem({
    super.key,
    required this.reminder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = reminder.status == ReminderStatus.completed;
    
    final now = DateTime.now();
    final isOverdue = !isCompleted && reminder.dateTime.isBefore(now);

    final priorityColor = _getPriorityColor(reminder.priority);
    final priorityName = _getPriorityName(reminder.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04), // Subtle glass effect
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Side Color Indicator
              Container(
                width: 4,
                color: priorityColor.withOpacity(0.8),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reminder.title,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Icon(
                            _getCategoryIcon(reminder.category),
                            color: Colors.white.withOpacity(0.4),
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${DateFormat('h:mm a').format(reminder.dateTime)} · ${reminder.description ?? 'Vault Context'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$priorityName Tag',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
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

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return const Color(0xFFC084FC); // Purple
      case Priority.medium:
        return const Color(0xFF818CF8); // Indigo
      case Priority.low:
        return const Color(0xFF34D399); // Green
      default:
        return const Color(0xFF818CF8);
    }
  }

  String _getPriorityName(Priority priority) {
    switch (priority) {
      case Priority.high:
        return 'Purple';
      case Priority.medium:
        return 'Indigo';
      case Priority.low:
        return 'Green';
      default:
        return 'Indigo';
    }
  }

  IconData _getCategoryIcon(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.work:
        return Icons.group_outlined;
      case ReminderCategory.health:
        return Icons.fitness_center_rounded;
      case ReminderCategory.finance:
        return Icons.account_balance_wallet_rounded;
      case ReminderCategory.personal:
        return Icons.person_outline_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  void _handleComplete(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final viewModel = context.read<ReminderViewModel>();
    await viewModel.completeReminder(reminder.id);
  }

  void _handleDelete(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final viewModel = context.read<ReminderViewModel>();
    await viewModel.deleteReminder(reminder.id);
  }

  void _handleWhatsAppSync(BuildContext context) async {
    final message = "⏰ Autonomous Vault Vault: ${reminder.title}\nTime: ${DateTimeUtils.formatDateTime(reminder.dateTime)}";
    final url = "https://wa.me/?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

class _CategoryStyle {
  final Color color;
  const _CategoryStyle({required this.color});
}
