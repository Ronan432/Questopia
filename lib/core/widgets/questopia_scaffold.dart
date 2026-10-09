import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'window_title_bar.dart';

class QuestopiaScaffold extends StatelessWidget {
  const QuestopiaScaffold({
    super.key,
    required this.title,
    required this.body,
    this.titleWidget,
    this.actions,
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  const QuestopiaScaffold.simple({
    super.key,
    required this.title,
    required this.body,
    this.titleWidget,
    this.actions,
  })  : bottomNavigationBar = null,
        extendBody = false;

  final String title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final showCustomTitleBar = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          showCustomTitleBar ? 40 : kToolbarHeight,
        ),
        child: showCustomTitleBar
            ? WindowTitleBar(title: title)
            : AppBar(
                title: titleWidget ?? Text(title),
                actions: actions,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
      ),
      body: body,
      extendBody: extendBody,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
