import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'window_title_bar.dart';

class QuestopiaScaffold extends StatelessWidget {
  const QuestopiaScaffold({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.titleWidget,
    this.actions,
    this.customAppBar,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.isAppBarVisible = true,
  });

  const QuestopiaScaffold.simple({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.titleWidget,
    this.actions,
    this.customAppBar,
  })  : bottomNavigationBar = null,
        extendBody = false,
        isAppBarVisible = true;

  final String title;
  final Widget? leading;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? customAppBar;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool isAppBarVisible;

  @override
  Widget build(BuildContext context) {
    var isDesktop = false;
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.windows) isDesktop = true;
      if (defaultTargetPlatform == TargetPlatform.macOS) isDesktop = true;
      if (defaultTargetPlatform == TargetPlatform.linux) isDesktop = true;
    }
    final showCustomTitleBar = isDesktop;

    final targetHeight = showCustomTitleBar ? 40.0 : kToolbarHeight;

    PreferredSizeWidget? resolvedAppBar;
    if (customAppBar != null) {
      if (!showCustomTitleBar) {
        resolvedAppBar = customAppBar;
      }
    }

    resolvedAppBar ??= PreferredSize(
      preferredSize: Size.fromHeight(targetHeight),
      child: AnimatedSlide(
        offset: isAppBarVisible ? Offset.zero : const Offset(0, -1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isAppBarVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
            ignoring: !isAppBarVisible,
            child: showCustomTitleBar
                ? WindowTitleBar(
                    title: title,
                    leading: leading,
                    titleWidget: titleWidget,
                    actions: actions,
                  )
                : AppBar(
                    leading: leading,
                    title: titleWidget ?? Text(title),
                    actions: actions,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: resolvedAppBar,
      body: body,
      extendBody: extendBody,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
