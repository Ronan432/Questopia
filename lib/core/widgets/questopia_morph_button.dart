import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum QuestopiaMorphButtonStyle { filled, tonal, outlined }

/// Interactive Material You button that smoothly morphs its border radius between 20 (idle) and 8 (pressed).
class QuestopiaMorphButton extends StatefulWidget {
  const QuestopiaMorphButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.style = QuestopiaMorphButtonStyle.filled,
    this.isDestructive = false,
  });

  const QuestopiaMorphButton.outlined({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.isDestructive = false,
  }) : style = QuestopiaMorphButtonStyle.outlined;

  const QuestopiaMorphButton.tonal({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.isDestructive = false,
  }) : style = QuestopiaMorphButtonStyle.tonal;

  const QuestopiaMorphButton.filled({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.isDestructive = false,
  }) : style = QuestopiaMorphButtonStyle.filled;

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final QuestopiaMorphButtonStyle style;
  final bool isDestructive;

  @override
  State<QuestopiaMorphButton> createState() => _QuestopiaMorphButtonState();
}

class _QuestopiaMorphButtonState extends State<QuestopiaMorphButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    HapticFeedback.selectionClick();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEnabled = widget.onPressed != null;

    Color bgColor;
    Color fgColor;
    Border? border;

    switch (widget.style) {
      case QuestopiaMorphButtonStyle.filled:
        if (widget.isDestructive) {
          bgColor = isEnabled
              ? (_isPressed
                  ? colors.error.withValues(alpha: 0.85)
                  : colors.error)
              : colors.onSurface.withValues(alpha: 0.12);
          fgColor = isEnabled
              ? colors.onError
              : colors.onSurface.withValues(alpha: 0.38);
        } else {
          bgColor = isEnabled
              ? (_isPressed
                  ? colors.primary.withValues(alpha: 0.85)
                  : colors.primary)
              : colors.onSurface.withValues(alpha: 0.12);
          fgColor = isEnabled
              ? colors.onPrimary
              : colors.onSurface.withValues(alpha: 0.38);
        }
        break;
      case QuestopiaMorphButtonStyle.tonal:
        bgColor = isEnabled
            ? (_isPressed
                ? colors.secondaryContainer.withValues(alpha: 0.85)
                : colors.secondaryContainer)
            : colors.onSurface.withValues(alpha: 0.12);
        fgColor = isEnabled
            ? colors.onSecondaryContainer
            : colors.onSurface.withValues(alpha: 0.38);
        break;
      case QuestopiaMorphButtonStyle.outlined:
        bgColor = _isPressed
            ? colors.surfaceContainerHighest.withValues(alpha: 0.6)
            : Colors.transparent;
        fgColor = isEnabled
            ? (widget.isDestructive ? colors.error : colors.onSurface)
            : colors.onSurface.withValues(alpha: 0.38);
        border = Border.all(
          color: isEnabled
              ? (_isPressed
                  ? colors.primary.withValues(alpha: 0.6)
                  : colors.outlineVariant.withValues(alpha: 0.5))
              : colors.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        );
        break;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: const BoxConstraints(minHeight: 36, minWidth: 64),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(_isPressed ? 8.0 : 20.0),
          border: border,
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: fgColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          child: IconTheme(
            data: IconThemeData(
              color: fgColor,
              size: 16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 6),
                ],
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
