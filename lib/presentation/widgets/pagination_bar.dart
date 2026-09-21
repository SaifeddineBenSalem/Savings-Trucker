import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/savings_provider.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.month,
  });

  final int month;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsProvider>();
    final currentPage = provider.currentPageForMonth(month);
    final pageCount = provider.pageCountForMonth(month);
    final totalUnits = provider.totalUnitsForMonth(month);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (totalUnits == 0) return const SizedBox.shrink();

    final isFirst = currentPage <= 0;
    final isLast = currentPage >= pageCount - 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isFirst ? null : () => provider.previousPage(month),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('BACK'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Page ${currentPage + 1} / $pageCount',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: FilledButton(
              onPressed: isLast ? null : () => provider.nextPage(month),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('NEXT'),
            ),
          ),
        ],
      ),
    );
  }
}
