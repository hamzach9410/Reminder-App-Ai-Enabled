import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'presentation/viewmodels/reminder_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'presentation/screens/home_screen.dart';

/// main application widget with proper dependency injection
class AutonomousReminderApp extends StatelessWidget {
  final ReminderViewModel reminderViewModel;
  final ThemeViewModel themeViewModel;

  const AutonomousReminderApp({
    super.key,
    required this.reminderViewModel,
    required this.themeViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeViewModel),
        ChangeNotifierProvider.value(value: reminderViewModel),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, _) {
          return MaterialApp(
            title: 'Autonomous Vault',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeViewModel.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
