import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'window_title_bar.dart';

class QuestopiaScaffold extends StatelessWidget {
  const QuestopiaScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
  });

  const QuestopiaScaffold.simple({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  }) : bottomNavigationBar = null;

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

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
                title: Text(title),
                actions: actions,
              ),
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
