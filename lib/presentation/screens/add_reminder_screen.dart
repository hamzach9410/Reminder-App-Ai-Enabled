import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../data/models/reminder_model.dart';
import '../../core/constants/enums.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/constants/app_constants.dart';
import '../viewmodels/reminder_viewmodel.dart';
import '../widgets/priority_selector_widget.dart';
import '../widgets/recurrence_selector_widget.dart';
import '../widgets/listening_waveform.dart';
import '../../core/services/nlp_service.dart' hide ReminderCategory;

/// Premium Add Reminder Screen following NoteWise's "Note-first" design.
/// Features a massive hero input, category chips, and a fluid voice UI.
class AddReminderScreen extends StatefulWidget {
  final AutonomousParsedReminder? initialParsed;

  const AddReminderScreen({
    super.key,
    this.initialParsed,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late Priority _priority;
  late RecurrenceType _recurrence;
  late ReminderCategory _category;
  
  bool _isListening = false;
  bool _isSaving = false;
  List<ReminderModel> _conflicts = [];

  @override
  void initState() {
    super.initState();
    // Initialize with parsed data if avInferencelable, otherwise defaults
    if (widget.initialParsed != null) {
      _titleController.text = widget.initialParsed!.title;
      _selectedDate = widget.initialParsed!.scheduledTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.initialParsed!.scheduledTime);
      _priority = widget.initialParsed!.priority;
      _recurrence = widget.initialParsed!.recurrence;
      _category = ReminderCategory.personal;
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _priority = Priority.medium;
      _recurrence = RecurrenceType.none;
      _category = ReminderCategory.personal;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<ReminderViewModel>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
        ),
        actions: [
          _buildSaveButton(context),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 20),
            
            // Hero Category Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReminderCategory.values.map((cat) {
                  final isSelected = cat == _category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(cat.emoji + ' ' + cat.displayName.toUpperCase()),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _category = cat),
                      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      selectedColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide.none,
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Hero Input (Note style)
            TextFormField(
              controller: _titleController,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: GoogleFonts.inter(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
                border: InputBorder.none,
              ),
              maxLines: null,
              onChanged: (text) => _onTextChanged(text, viewModel),
            ),
            const SizedBox(height: 40),

            // Voice Interaction Area
            Center(
              child: GestureDetector(
                onTap: () => _toggleVoice(viewModel),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isListening 
                        ? theme.colorScheme.primaryContainer 
                        : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _isListening 
                        ? const ListeningWaveform()
                        : Icon(Icons.mic_none_rounded, size: 32, color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _isListening ? 'LISTENING...' : 'TAP TO SPEAK',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Selectors Section (NoteWise style pickers)
            _buildSectionHeader('TIME & DATE'),
            const SizedBox(height: 12),
            _buildTilePicker(
              icon: Icons.calendar_month_rounded,
              label: DateTimeUtils.formatDate(_selectedDate),
              onTap: _selectDate,
            ),
            const SizedBox(height: 8),
            _buildTilePicker(
              icon: Icons.access_time_filled_rounded,
              label: _selectedTime.format(context),
              onTap: _selectTime,
            ),
            const SizedBox(height: 32),

            PrioritySelectorWidget(
              selectedPriority: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 32),

            RecurrenceSelectorWidget(
              selectedRecurrence: _recurrence,
              onChanged: (r) => setState(() => _recurrence = r),
            ),
            if (_conflicts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildConflictHUD(),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }

  Widget _buildTilePicker({required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextButton(
        onPressed: _isSaving ? null : _saveReminder,
        style: TextButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(
                'SAVE',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
      ),
    );
  }

  Future<void> _onTextChanged(String text, ReminderViewModel viewModel) async {
    if (text.length > 5) {
      final tasks = await viewModel.processAutonomousIntent(text);
      if (tasks.isNotEmpty && mounted) {
        final primary = tasks.first;
        setState(() {
          _selectedDate = primary.reminder.scheduledTime;
          _selectedTime = TimeOfDay.fromDateTime(primary.reminder.scheduledTime);
          _priority = primary.reminder.priority;
          _recurrence = primary.reminder.recurrence;
          _conflicts = primary.collisions;
        });
      }
    } else if (_conflicts.isNotEmpty) {
      setState(() => _conflicts = []);
    }
  }

  Widget _buildConflictHUD() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule Conflict',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                Text(
                  'Overlap with: ${_conflicts.map((c) => c.title).join(", ")}',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleVoice(ReminderViewModel viewModel) async {
    HapticFeedback.mediumImpact();
    if (_isListening) {
      setState(() => _isListening = false);
      // Logic handled in viewmodel subscription usually, or via callback
      return;
    }

    setState(() => _isListening = true);
    await viewModel.startVoiceInput(onResult: (parsedList) {
      if (mounted && parsedList.isNotEmpty) {
        final parsed = parsedList.first;
        setState(() {
          _titleController.text = parsed.title;
          _selectedDate = parsed.scheduledTime;
          _selectedTime = TimeOfDay.fromDateTime(parsed.scheduledTime);
          _priority = parsed.priority;
          _recurrence = parsed.recurrence;
          _isListening = false;
        });
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _saveReminder() async {
    if (_titleController.text.isEmpty) return;
    
    final dateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    // NoteWise Parity: High-risk confirmation
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    final isLateNight = dateTime.hour >= 22 || dateTime.hour < 6;
    
    if (difference > 7 || isLateNight) {
      final reason = difference > 7 ? 'scheduled for more than 1 week away' : 'scheduled for late night';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Vault Entry', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Text('This reminder is $reason. Are you sure?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
            TextButton(
              onPressed: () => Navigator.pop(context, true), 
              child: Text('PROCEED', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);

    // Use TaskOrchestrator to handle potential multi-intent splitting (e.g. "A and B")
    final viewModel = context.read<ReminderViewModel>();
    final results = await viewModel.processAutonomousIntent(_titleController.text.trim());
    
    bool allSuccess = true;
    if (results.isEmpty) {
      // Logic fallback: If orchestrator returns nothing, save one manual entry
      final reminder = ReminderModel.create(
        title: _titleController.text.trim(),
        dateTime: dateTime,
        priority: _priority,
        recurrence: _recurrence,
        category: _category,
      );
      allSuccess = await viewModel.addReminder(reminder);
    } else {
      for (final task in results) {
        // Apply the user's manual UI overrides (Date/Time/Priority) to each split intent
        final reminder = task.reminder.copyWith(
          dateTime: dateTime, 
          priority: _priority,
          recurrence: _recurrence,
          category: _category,
        );
        final success = await viewModel.addReminder(reminder);
        if (!success) allSuccess = false;
      }
    }

    if (allSuccess && mounted) {
      HapticFeedback.heavyImpact();
      Navigator.pop(context, true);
    } else {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
