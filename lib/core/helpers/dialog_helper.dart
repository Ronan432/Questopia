import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/questopia_morph_button.dart';

export '../widgets/questopia_morph_button.dart';

/// Shows a unified Questopia modal dialog with clean fade, scale, and backdrop blur.
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
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return capturedThemes.wrap(builder(dialogContext));
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, _) {
            final scale =
                lerpDouble(0.92, 1.0, curvedAnimation.value) ?? 1.0;
            final sigma = curvedAnimation.value * 10.0;

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

/// Unified modal dialog frame with static Material You geometry and compact padding.
class QuestopiaDialog extends StatelessWidget {
  const QuestopiaDialog({
    super.key,
    this.icon,
    this.title,
    required this.content,
    this.actions,
    this.maxWidth = 320,
  });

  final Widget? icon;
  final Widget? title;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        minWidth: 260,
      ),
      child: Material(
        color: colors.surfaceContainer,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.35),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Align(
                  alignment: Alignment.center,
                  child: IconTheme(
                    data: IconThemeData(
                      size: 26,
                      color: colors.primary,
                    ),
                    child: icon!,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (title != null) ...[
                DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  textAlign:
                      icon != null ? TextAlign.center : TextAlign.start,
                  child: title!,
                ),
                const SizedBox(height: 12),
              ],
              Flexible(
                child: SingleChildScrollView(
                  child: content,
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 18),
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
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

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
        QuestopiaMorphButton.outlined(
          onPressed: () {
            if (onCancel != null) {
              onCancel!();
            } else {
              Navigator.of(context).pop(false);
            }
          },
          child: Text(cancelLabel),
        ),
        QuestopiaMorphButton.filled(
          onPressed: () {
            if (onConfirm != null) {
              onConfirm!();
            } else {
              Navigator.of(context).pop(true);
            }
          },
          isDestructive: isDestructive,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
