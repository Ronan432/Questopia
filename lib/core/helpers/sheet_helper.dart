import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a Modal Bottom Sheet with backdrop blur, constrained so its maximum
/// height stops right at the status bar and custom desktop titlebar.
Future<T?> showQuestopiaSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showDragHandle = true,
  bool useRootNavigator = true,
  Color? backgroundColor,
}) {
  final mediaQuery = MediaQuery.of(context);
  final statusBarHeight = mediaQuery.padding.top;
  final showCustomTitleBar = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);
  final titleBarHeight = showCustomTitleBar ? 40.0 : 0.0;
  final maxSheetHeight = mediaQuery.size.height - statusBarHeight - titleBarHeight;
  final colors = Theme.of(context).colorScheme;
  final sheetBgColor = backgroundColor ?? colors.surfaceContainerHigh;
  final isDark = ThemeData.estimateBrightnessForColor(sheetBgColor) == Brightness.dark;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: false,
    useSafeArea: false,
    useRootNavigator: useRootNavigator,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    backgroundColor: Colors.transparent,
    elevation: 0,
    constraints: BoxConstraints(
      maxHeight: maxSheetHeight,
    ),
    builder: (sheetContext) {
      final overlayStyle = SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            colors.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      );

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const SizedBox.expand(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: sheetBgColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
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
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 6),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                    Flexible(
                      child: builder(sheetContext),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
