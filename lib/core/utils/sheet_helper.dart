import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shows a Modal Bottom Sheet constrained so its maximum height stops right at
/// the status bar and custom desktop titlebar without covering them.
Future<T?> showQuestopiaSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showDragHandle = true,
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

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    useSafeArea: true,
    backgroundColor: backgroundColor ?? colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    constraints: BoxConstraints(
      maxHeight: maxSheetHeight,
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: builder(sheetContext),
      );
    },
  );
}
