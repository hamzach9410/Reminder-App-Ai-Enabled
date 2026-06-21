import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/enums.dart';
import '../viewmodels/reminder_viewmodel.dart';
import '../widgets/reminder_list_item.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/today_header.dart';
import '../widgets/suggestion_card.dart';
import '../widgets/stat_cards.dart';
import '../widgets/timeline_calendar.dart';
import 'add_reminder_screen.dart';
import 'reminder_detail_screen.dart';
import 'settings_screen.dart';
import '../../data/models/reminder_model.dart';
import '../../core/services/nlp_service.dart';

/// Premium Home Screen following NoteWise's clean, hero-driven design.
/// Features a statistical dashboard, temporal timeline, and categorized Vault.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black, // Pure black for maximum glow contrast
      body: Stack(
        children: [
          // High-Intensity Mesh Background
          Positioned(
            top: -100,
            left: -100,
            child: _GlowAnchor(color: const Color(0xFF7C3AED).withOpacity(0.4), size: 500, blur: 150),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: _GlowAnchor(color: const Color(0xFF10B981).withOpacity(0.3), size: 500, blur: 150),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: _GlowAnchor(color: const Color(0xFF8B5CF6).withOpacity(0.15), size: 500, blur: 120),
          ),
          
          Consumer<ReminderViewModel>(
            builder: (context, viewModel, _) {
              final pending = viewModel.pendingReminders;
              final completed = viewModel.completedReminders;
              final suggestions = viewModel.suggestions;
              final nextReminder = _findNextUpcomingReminder(viewModel.reminders);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Premium Transparent AppBar
                  SliverAppBar(
                    floating: true,
                    pinned: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                      onPressed: () {},
                    ),
                    centerTitle: true,
                    title: Text(
                      'Vault',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  
                  // Semantic Search Bar (Floating Concept)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: TodayHeader(nextReminder: nextReminder),
                    ),
                  ),
                  
                  // Timeline Calendar
                  SliverToBoxAdapter(
                    child: TimelineCalendar(
                      selectedDate: viewModel.selectedDate,
                      onDateSelected: (date) => viewModel.setSelectedDate(date),
                    ),
                  ),

                  if (viewModel.isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              if (suggestions.isNotEmpty && viewModel.selectedDate == null) ...[
                                _SectionHeader(title: 'AUTOMATED PROCESSING'),
                                const SizedBox(height: 12),
                                ...suggestions.map((s) => SuggestionCard(
                                  suggestion: s,
                                  onPrimaryAction: () => viewModel.applySuggestion(s),
                                  onDismiss: () => viewModel.dismissSuggestion(s.id),
                                )),
                                const SizedBox(height: 32),
                              ],

                              _SectionHeader(
                                title: viewModel.selectedDate == null 
                                  ? 'dashboard.scheduled'.tr().toUpperCase() 
                                  : 'daily ARCHIVE',
                              ),
                              const SizedBox(height: 12),
                              
                              final nextReminder = _findNextUpcomingReminder(allReminders);
                              final pendingWithoutNext = pending.where((r) => r.id != nextReminder?.id).toList();

                              if (pendingWithoutNext.isEmpty && completed.isEmpty && nextReminder == null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: EmptyStateWidget(
                                    icon: Icons.auto_awesome_rounded,
                                    message: 'dashboard.empty.title'.tr(),
                                    subtitle: 'dashboard.empty.description'.tr(),
                                  ),
                                )
                              else ...[
                                ...pendingWithoutNext.map((r) => ReminderListItem(
                                  reminder: r,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ReminderDetailscreen(reminder: r)),
                                  ),
                                )),
                                if (completed.isNotEmpty) ...[
                                  const SizedBox(height: 32),
                                  _SectionHeader(title: 'dashboard.completed'.tr().toUpperCase()),
                                  const SizedBox(height: 12),
                                  ...completed.map((r) => ReminderListItem(
                                    reminder: r,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ReminderDetailscreen(reminder: r)),
                                    ),
                                  )),
                                ],
                              ],
                              
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _GlassmorphicBottomBar(
        onMicPressed: () {
          final vm = context.read<ReminderViewModel>();
          vm.startVoiceInput(
            onResult: (List<AutonomousParsedReminder> parsedList) {
              if (parsedList.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddReminderScreen(initialParsed: parsedList.first),
                  ),
                );
              }
            },
          );
        },
        onAddPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddReminderScreen()),
        ),
      ),
    );
  }

  ReminderModel? _findNextUpcomingReminder(List<ReminderModel> reminders) {
    final now = DateTime.now();
    ReminderModel? next;
    DateTime? nextTime;

    for (var r in reminders) {
      if (r.status == ReminderStatus.completed) continue;
      
      final rTime = r.scheduledTime;
      if (rTime.isAfter(now)) {
        if (nextTime == null || rTime.isBefore(nextTime)) {
          nextTime = rTime;
          next = r;
        }
      }
    }
    return next;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 3.0,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }
}

class _GlowAnchor extends StatelessWidget {
  final Color color;
  final double size;
  final double blur;

  const _GlowAnchor({required this.color, required this.size, required this.blur});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class _GlassmorphicBottomBar extends StatelessWidget {
  final VoidCallback onMicPressed;
  final VoidCallback onAddPressed;

  const _GlassmorphicBottomBar({required this.onMicPressed, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 90,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glass Base
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavIcon(icon: Icons.home_filled, isActive: true),
                    _NavIcon(icon: Icons.search_rounded, isActive: false),
                    const SizedBox(width: 80), // Space for center FAB
                    _NavIcon(icon: Icons.calendar_today_rounded, isActive: false),
                    _NavIcon(icon: Icons.person_outline_rounded, isActive: false),
                  ],
                ),
              ),
            ),
          ),
          
          // Center Mic FAB
          GestureDetector(
            onTap: onMicPressed,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  const _NavIcon({required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon, 
      color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.5),
      size: 26,
    );
  }
}
