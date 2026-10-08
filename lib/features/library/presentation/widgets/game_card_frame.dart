import 'package:flutter/material.dart';

class GameCardFrame extends StatelessWidget {
  const GameCardFrame({
    super.key,
    required this.posterWidget,
    required this.titleWidget,
    required this.subtitleWidget,
    required this.actionsWidget,
    this.onTap,
    this.onLongPress,
  });

  final Widget posterWidget;
  final Widget titleWidget;
  final Widget subtitleWidget;
  final Widget actionsWidget;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            posterWidget,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 2),
                    subtitleWidget,
                    const Spacer(),
                    actionsWidget,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
