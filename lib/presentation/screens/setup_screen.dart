import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/services/savings_engine.dart';
import '../providers/savings_provider.dart';
import '../widgets/credits_modal.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isSaving = false;
  bool _isLocked = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveTarget() async {
    if (!_formKey.currentState!.validate() || _isLocked) return;

    final millimes = CurrencyFormatter.parseTargetInput(_amountController.text)!;

    setState(() => _isSaving = true);
    await context.read<SavingsProvider>().configureTarget(millimes);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isLocked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [AppColors.darkCard, AppColors.darkSurface]
                          : [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.flag_rounded, color: Colors.white, size: 36),
                      const SizedBox(height: 16),
                      Text(
                        'Set Your Savings Goal',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your target in Tunisian Dinars. '
                        'Format: dinars,millimes — e.g. 123,200',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _amountController,
                  enabled: !_isLocked,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Target Amount',
                    hintText: '123,200',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    suffixIcon: _isLocked
                        ? const Icon(Icons.lock_outline, color: AppColors.warning)
                        : null,
                  ),
                  validator: (value) {
                    final parsed = CurrencyFormatter.parseTargetInput(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Use format: dinars,millimes (e.g. 123,200)';
                    }
                    if (!SavingsEngine.isTargetRepresentable(parsed)) {
                      return 'Amount must be a multiple of 100 millimes '
                          '(uses 100, 200, 500, 1000, 2000, 5000 units)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? AppColors.accent : AppColors.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Once saved, your target becomes permanent. '
                          'Use Reset App Data (password: 1234) to change it.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLocked || _isSaving ? null : _saveTarget,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isLocked ? 'Target Locked' : 'Save Target'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => handleResetAction(context),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset App Data'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
