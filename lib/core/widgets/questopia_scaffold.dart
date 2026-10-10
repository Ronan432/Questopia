import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'window_title_bar.dart';

/// Scaffold with a fully collapsible header bar that animates its own height
/// away so no empty background strip is left behind.
class QuestopiaScaffold extends StatefulWidget {
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
  State<QuestopiaScaffold> createState() => _QuestopiaScaffoldState();
}

class _QuestopiaScaffoldState extends State<QuestopiaScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.isAppBarVisible ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant QuestopiaScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAppBarVisible == oldWidget.isAppBarVisible) return;
    if (widget.isAppBarVisible) {
      _headerController.forward();
    } else {
      _headerController.reverse();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  bool _isDesktopPlatform() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    final showCustomTitleBar = _isDesktopPlatform();
    final topInset = showCustomTitleBar
        ? 0.0
        : MediaQuery.paddingOf(context).top;
    final naturalHeight =
        (showCustomTitleBar ? 40.0 : kToolbarHeight) + topInset;

    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_headerController.value);
        final visibleHeight = naturalHeight * t;
        // Scaffold adds the top inset on top of the reported size, so the
        // compensation keeps the total height in sync with the animation.
        final reportedHeight =
            (visibleHeight - topInset).clamp(0.0, double.infinity);

        final bar = showCustomTitleBar
            ? WindowTitleBar(
                title: widget.title,
                leading: widget.leading,
                titleWidget: widget.titleWidget,
                actions: widget.actions,
              )
            : AppBar(
                leading: widget.leading,
                title: widget.titleWidget ?? Text(widget.title),
                actions: widget.actions,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                backgroundColor: Theme.of(context).colorScheme.surface,
              );

        PreferredSizeWidget? appBar;
        if (widget.customAppBar != null && !showCustomTitleBar) {
          appBar = widget.customAppBar;
        } else {
          appBar = PreferredSize(
            preferredSize: Size.fromHeight(reportedHeight),
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: naturalHeight,
                maxHeight: naturalHeight,
                child: Opacity(
                  opacity: t,
                  child: IgnorePointer(
                    ignoring: _headerController.value < 0.99,
                    child: bar,
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: widget.body,
          extendBody: widget.extendBody,
          bottomNavigationBar: widget.bottomNavigationBar,
        );
      },
    );
  }
}