import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/enums.dart';
import '../../data/models/reminder_model.dart';

class StatCards extends StatelessWidget {
  final List<ReminderModel> reminders;

  const StatCards({super.key, required this.reminders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = reminders.where((r) => 
      r.dateTime.isAfter(now) && r.status != ReminderStatus.completed
    ).length;
    
    final completed = reminders.where((r) => 
      r.status == ReminderStatus.completed
    ).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildVaultCard(
              context: context,
              title: 'UNITS ACTIVE',
              value: upcoming.toString(),
              colors: [const Color(0xFF8B5CF6), const Color(0xFF6366F1)],
              icon: Icons.auto_graph_rounded,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildVaultCard(
              context: context,
              title: 'VAULTED',
              value: completed.toString(),
              colors: [const Color(0xFF10B981), const Color(0xFF059669)],
              icon: Icons.verified_user_rounded,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultCard({
    required BuildContext context,
    required String title,
    required String value,
    required List<Color> colors,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              Icon(icon, color: colors.first, size: 14),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 14),
          // Micro-progress bar for aesthetic
          Container(
            height: 2.5,
            width: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

