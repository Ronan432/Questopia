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
  final topPadding = mediaQuery.padding.top + (showCustomTitleBar ? 40.0 : 24.0);
  final maxSheetHeight = (mediaQuery.size.height - topPadding).clamp(200.0, mediaQuery.size.height);
  final colors = Theme.of(context).colorScheme;
  final sheetBgColor = backgroundColor ?? colors.surfaceContainerHigh;
  final isDark = ThemeData.estimateBrightnessForColor(sheetBgColor) == Brightness.dark;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    enableDrag: true,
    isDismissible: true,
    showDragHandle: false,
    useSafeArea: true,
    useRootNavigator: useRootNavigator,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    backgroundColor: Colors.transparent,
    elevation: 0,
    constraints: BoxConstraints(
      maxHeight: maxSheetHeight,
    ),
    builder: (sheetContext) {
      final sheetMediaQuery = MediaQuery.of(sheetContext);
      final currentTopPadding = sheetMediaQuery.padding.top + (showCustomTitleBar ? 40.0 : 24.0);
      final currentMaxHeight = (sheetMediaQuery.size.height - currentTopPadding).clamp(200.0, sheetMediaQuery.size.height);

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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: currentMaxHeight,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBgColor.withValues(alpha: 0.82),
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
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 38,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3),
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
            ),
          ),
        ),
      );
    },
  );
}
