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
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return capturedThemes.wrap(builder(dialogContext));
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return AnimatedBuilder(
        animation: curvedAnimation,
        builder: (context, _) {
          final t = curvedAnimation.value;
          final sigma = t * 10.0;

          return FadeTransition(
            opacity: curvedAnimation,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: child,
            ),
          );
        },
      );
    },
  );
}

/// Unified modal dialog frame with morph-shaping animation, icon, title, and compact actions.
class QuestopiaDialog extends StatelessWidget {
  const QuestopiaDialog({
    super.key,
    this.icon,
    this.title,
    required this.content,
    this.actions,
    this.maxWidth = 340,
  });

  final Widget? icon;
  final Widget? title;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final anim = ModalRoute.of(context)?.animation;

    Widget buildCard(double radius) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minWidth: 280,
        ),
        child: Material(
          color: colors.surfaceContainer,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
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

    return Center(
      child: anim != null
          ? AnimatedBuilder(
              animation: anim,
              builder: (context, _) {
                final curved = CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );
                final radius = lerpDouble(56.0, 24.0, curved.value) ?? 24.0;
                final scale = lerpDouble(0.84, 1.0, curved.value) ?? 1.0;
                return Transform.scale(
                  scale: scale,
                  child: buildCard(radius),
                );
              },
            )
          : buildCard(24.0),
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
