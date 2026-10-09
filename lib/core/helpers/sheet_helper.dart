import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a Modal Bottom Sheet with backdrop blur, constrained strictly so its
/// drag handle and top edges never cross or overlap the status bar or custom titlebar.
Future<T?> showQuestopiaSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showDragHandle = true,
  bool useRootNavigator = true,
  Color? backgroundColor,
}) {
  final mediaQuery = MediaQuery.of(context);
  final showCustomTitleBar = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);
  final topPadding =
      mediaQuery.padding.top + (showCustomTitleBar ? 40.0 : 24.0);
  final maxSheetHeight = (mediaQuery.size.height - topPadding)
      .clamp(200.0, mediaQuery.size.height);
  final colors = Theme.of(context).colorScheme;
  final sheetBgColor = backgroundColor ?? colors.surfaceContainerLowest;
  final isDark =
      ThemeData.estimateBrightnessForColor(sheetBgColor) == Brightness.dark;

  final capturedThemes =
      InheritedTheme.capture(from: context, to: Navigator.of(context).context);

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    _BlurredModalBottomSheetRoute<T>(
      capturedThemes: capturedThemes,
      isScrollControlled: isScrollControlled,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      modalBarrierColor: Colors.black.withValues(alpha: 0.35),
      backgroundColor: Colors.transparent,
      elevation: 0,
      constraints: BoxConstraints(
        maxHeight: maxSheetHeight,
      ),
      builder: (sheetContext) {
        final sheetMediaQuery = MediaQuery.of(sheetContext);
        final currentTopPadding =
            sheetMediaQuery.padding.top + (showCustomTitleBar ? 40.0 : 24.0);
        final currentMaxHeight =
            (sheetMediaQuery.size.height - currentTopPadding)
                .clamp(200.0, sheetMediaQuery.size.height);

        final overlayStyle = SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: colors.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: currentMaxHeight,
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBgColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  bottom: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showDragHandle) ...[
                        _InteractiveDragHandle(isDark: isDark),
                      ],
                      Flexible(
                        child: builder(sheetContext),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _BlurredModalBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _BlurredModalBottomSheetRoute({
    required super.builder,
    super.capturedThemes,
    super.barrierLabel,
    super.barrierOnTapHint,
    super.backgroundColor,
    super.elevation,
    super.shape,
    super.clipBehavior,
    super.modalBarrierColor,
    super.isDismissible = true,
    super.enableDrag = true,
    super.showDragHandle,
    super.isScrollControlled = false,
    super.settings,
    super.transitionAnimationController,
    super.anchorPoint,
    super.useSafeArea = false,
    super.constraints,
  });

  @override
  ImageFilter? get filter => ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0);
}

/// Centered header pill styling for modal bottom sheets.
class QuestopiaSheetHeaderPill extends StatelessWidget {
  const QuestopiaSheetHeaderPill({
    super.key,
    required this.title,
    this.icon,
  });

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colors.secondaryContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: colors.onSecondaryContainer),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.onSecondaryContainer,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveDragHandle extends StatefulWidget {
  const _InteractiveDragHandle({required this.isDark});

  final bool isDark;

  @override
  State<_InteractiveDragHandle> createState() => _InteractiveDragHandleState();
}

class _InteractiveDragHandleState extends State<_InteractiveDragHandle> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.95)
        : Colors.black.withValues(alpha: 0.85);
    final idleColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.25);

    return Listener(
      onPointerDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
      },
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: _isPressed ? 52 : 36,
            height: _isPressed ? 6 : 4,
            decoration: BoxDecoration(
              color: _isPressed ? activeColor : idleColor,
              borderRadius: BorderRadius.circular(_isPressed ? 3 : 2),
            ),
          ),
        ),
      ),
    );
  }
}


