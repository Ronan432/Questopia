import 'dart:ui';

import 'package:flutter/material.dart';

/// Shows a unified Questopia modal dialog with morph-shaping scale transition and backdrop blur.
Future<T?> showQuestopiaDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final capturedThemes =
      InheritedTheme.capture(from: context, to: Navigator.of(context).context);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.60),
    useRootNavigator: useRootNavigator,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return capturedThemes.wrap(builder(dialogContext));
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      // Morph shaping from a tighter pill/rounded shape to standard dialog curvature
      final radius = Tween<double>(begin: 40.0, end: 28.0).evaluate(curvedAnimation);
      final scale = Tween<double>(begin: 0.88, end: 1.0).evaluate(curvedAnimation);
      final opacity = Tween<double>(begin: 0.0, end: 1.0).evaluate(curvedAnimation);

      return FadeTransition(
        opacity: curvedAnimation,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: opacity * 10.0,
            sigmaY: opacity * 10.0,
          ),
          child: ScaleTransition(
            scale: curvedAnimation,
            child: Transform.scale(
              scale: scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Unified modal dialog frame with Material 3 Expressive styling, icon, title, and action buttons.
class QuestopiaDialog extends StatelessWidget {
  const QuestopiaDialog({
    super.key,
    this.icon,
    this.title,
    required this.content,
    this.actions,
    this.maxWidth = 440,
  });

  final Widget? icon;
  final Widget? title;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: colors.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.35),
              width: 0.5,
            ),
          ),
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (icon != null) ...[
                  Align(
                    alignment: Alignment.center,
                    child: IconTheme(
                      data: IconThemeData(
                        size: 32,
                        color: colors.primary,
                      ),
                      child: icon!,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (title != null) ...[
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                    textAlign: icon != null ? TextAlign.center : TextAlign.start,
                    child: title!,
                  ),
                  const SizedBox(height: 16),
                ],
                Flexible(
                  child: SingleChildScrollView(
                    child: content,
                  ),
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i = 0; i < actions!.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions![i],
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Specialized confirmation dialog for destructive or general binary decisions.
class QuestopiaConfirmationDialog extends StatelessWidget {
  const QuestopiaConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return QuestopiaDialog(
      icon: icon != null
          ? Icon(
              icon,
              color: isDestructive ? colors.error : colors.primary,
            )
          : null,
      title: Text(title),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: colors.onSurfaceVariant,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(64, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: isDestructive ? colors.error : colors.primary,
            foregroundColor: isDestructive ? colors.onError : colors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(64, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
