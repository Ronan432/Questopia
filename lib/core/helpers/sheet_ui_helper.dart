import 'package:flutter/material.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../theme/questopia_theme.dart';

/// Standard responsive container wrapper for bottom sheets.
class QuestopiaSheetContainer extends StatelessWidget {
  const QuestopiaSheetContainer({
    super.key,
    required this.child,
    this.heightFactor = 0.85,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 20),
  });

  final Widget child;
  final double heightFactor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).colorScheme;

    return M3ETheme(
      data: M3EThemeData(
        colorScheme: QuestopiaTheme.m3eColorSchemeFrom(themeColors),
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * heightFactor,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Standard empty placeholder for lists and searches in bottom sheets.
class QuestopiaSheetEmptyState extends StatelessWidget {
  const QuestopiaSheetEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: colors.outline),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Standard search field for bottom sheets.
class QuestopiaSheetSearchBar extends StatelessWidget {
  const QuestopiaSheetSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        isDense: true,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

/// Standard page navigation bar for paginated sheets (e.g. Save slots).
class QuestopiaSheetPageNav extends StatelessWidget {
  const QuestopiaSheetPageNav({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        M3EButton.icon(
          onPressed: onPrev,
          size: M3EButtonSize.sm,
          style: M3EButtonStyle.outlined,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
          label: const Text('Prev'),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Page ${currentPage + 1} / $totalPages',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        M3EButton.icon(
          onPressed: onNext,
          size: M3EButtonSize.sm,
          style: M3EButtonStyle.outlined,
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          label: const Text('Next'),
        ),
      ],
    );
  }
}

/// Helper to show a standard snack bar message.
void showSheetSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
