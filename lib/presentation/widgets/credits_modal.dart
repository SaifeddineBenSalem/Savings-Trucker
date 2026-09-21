import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/savings_provider.dart';

/// Returns the credit amount entered by the user, or null if cancelled.
Future<int?> showCreditsModal(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _CreditsSheet(),
  );
}

class _CreditsSheet extends StatefulWidget {
  const _CreditsSheet();

  @override
  State<_CreditsSheet> createState() => _CreditsSheetState();
}

class _CreditsSheetState extends State<_CreditsSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = CurrencyFormatter.parseCreditInput(_controller.text)!;
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Credits',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Credits are applied in order from Month 1 onward. '
                'Unmatched credits stay in your buffer and count toward progress.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '1.5 DT or 300',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final parsed =
                      CurrencyFormatter.parseCreditInput(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Save Credits'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns the password if confirmed, null if cancelled, empty string if wrong flow.
Future<String?> showResetDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => const _ResetDialog(),
  );
}

class _ResetDialog extends StatefulWidget {
  const _ResetDialog();

  @override
  State<_ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<_ResetDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Reset All Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will erase your goal, units, credits, and progress. '
            'Enter the reset password to continue.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
            onSubmitted: (_) => Navigator.of(context).pop(_controller.text),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Reset'),
        ),
      ],
    );
  }
}

Future<void> handleResetAction(BuildContext context) async {
  final password = await showResetDialog(context);
  if (password == null || !context.mounted) return;

  final provider = context.read<SavingsProvider>();
  final success = await provider.resetApp(password);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? 'App data reset successfully.'
            : 'Incorrect password. Reset cancelled.',
      ),
      backgroundColor: success ? AppColors.success : AppColors.error,
    ),
  );
}

Future<void> handleCreditsAction(BuildContext context) async {
  final amount = await showCreditsModal(context);
  if (amount == null || !context.mounted) return;

  final provider = context.read<SavingsProvider>();
  final matched = await provider.addCredits(amount);

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        matched > 0
            ? 'Credits added — $matched unit(s) matched in order!'
            : 'Credits added to buffer — waiting for a matching unit.',
      ),
    ),
  );

  if (matched > 0) {
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        provider.clearRecentMatches();
      }
    });
  }
}
