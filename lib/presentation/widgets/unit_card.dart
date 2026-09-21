import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/savings_unit.dart';
import '../../data/models/unit_status.dart';

class UnitCard extends StatelessWidget {
  const UnitCard({
    super.key,
    required this.unit,
    required this.onTap,
    this.recentlyMatched = false,
    this.searchHighlighted = false,
    this.monthLabel,
  });

  final SavingsUnit unit;
  final VoidCallback onTap;
  final bool recentlyMatched;
  final bool searchHighlighted;
  final String? monthLabel;

  @override
  Widget build(BuildContext context) {
    final isDone = unit.status == UnitStatus.done;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = searchHighlighted
        ? AppColors.warning
        : recentlyMatched
            ? AppColors.success
            : (isDone
                ? AppColors.success.withValues(alpha: 0.35)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade200));

    return AnimatedOpacity(
      opacity: isDone ? 0.72 : 1,
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDone ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: searchHighlighted || recentlyMatched ? 2 : 1,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : Icons.savings_outlined,
                    color: isDone ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CurrencyFormatter.formatMillimes(unit.valueMillimes),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                      ),
                      const SizedBox(height: 4),
                      if (monthLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            monthLabel!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      Text(
                        isDone ? 'Collected' : 'Tap to confirm collection',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                if (recentlyMatched)
                  const Icon(Icons.auto_awesome, color: AppColors.success, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> showCollectionDialog(BuildContext context, SavingsUnit unit) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Collection'),
        content: Text(
          'Did you collect ${CurrencyFormatter.formatMillimes(unit.valueMillimes)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YES'),
          ),
        ],
      );
    },
  );
}
