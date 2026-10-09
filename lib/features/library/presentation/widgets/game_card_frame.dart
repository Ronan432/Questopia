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
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  });

  final Widget posterWidget;
  final Widget titleWidget;
  final Widget subtitleWidget;
  final Widget actionsWidget;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            posterWidget,
            Expanded(
              child: Padding(
                padding: contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        titleWidget,
                        const SizedBox(height: 1),
                        subtitleWidget,
                      ],
                    ),
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
