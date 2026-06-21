import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium empty state widget — NoteWise Vault style
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dashed-border circle with emoji-style icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : const Color(0xFFE4E4E7),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF4F4F5),
              ),
              child: Center(
                child: Text(
                  '📪',
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              message.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? const Color(0xFFA1A1AA)
                    : const Color(0xFF71717A),
                letterSpacing: 3.0,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF52525B)
                      : const Color(0xFFA1A1AA),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
