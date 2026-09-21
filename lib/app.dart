import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/services/storage_service.dart';
import 'presentation/providers/savings_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/setup_screen.dart';

class SavingsApp extends StatelessWidget {
  const SavingsApp({super.key, required this.provider});

  final SavingsProvider provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<SavingsProvider>(
        builder: (context, savings, _) {
          return MaterialApp(
            title: 'Savings Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            home: KeyedSubtree(
              key: ValueKey<bool>(savings.isConfigured),
              child: _buildHome(savings),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHome(SavingsProvider savings) {
    if (savings.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!savings.isConfigured) {
      return const SetupScreen();
    }

    return const HomeScreen();
  }
}

Future<SavingsProvider> bootstrap() async {
  final storage = await StorageService.init();
  final provider = SavingsProvider(storage);
  await provider.initialize();
  return provider;
}
