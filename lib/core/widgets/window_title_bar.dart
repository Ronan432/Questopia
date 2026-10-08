import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowTitleBar extends StatefulWidget implements PreferredSizeWidget {
  const WindowTitleBar({
    super.key,
    this.title = 'Questopia',
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) setState(() => _isMaximized = maximized);
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb &&
        (defaultTargetPlatform != TargetPlatform.windows &&
            defaultTargetPlatform != TargetPlatform.macOS &&
            defaultTargetPlatform != TargetPlatform.linux)) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    return DragToMoveArea(
      child: Container(
        height: 40,
        color: colors.surfaceContainerLow,
        child: Row(
          children: [
            const SizedBox(width: 12),
            const QuestopiaLogoIcon(size: 26),
            const Spacer(),
            _WindowButtons(
              isMaximized: _isMaximized,
              onMaximizeToggle: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                  if (mounted) setState(() => _isMaximized = false);
                } else {
                  await windowManager.maximize();
                  if (mounted) setState(() => _isMaximized = true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class QuestopiaLogoIcon extends StatelessWidget {
  const QuestopiaLogoIcon({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          Icons.auto_stories_rounded,
          size: size * 0.62,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons({
    required this.isMaximized,
    required this.onMaximizeToggle,
  });

  final bool isMaximized;
  final VoidCallback onMaximizeToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = colors.onSurfaceVariant;

    return Row(
      children: [
        _TitleBarButton(
          icon: Icon(Icons.remove_rounded, size: 16, color: iconColor),
          tooltip: 'Minimize',
          onPressed: () => windowManager.minimize(),
        ),
        _TitleBarButton(
          icon: Icon(
            isMaximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
            size: 14,
            color: iconColor,
          ),
          tooltip: isMaximized ? 'Restore' : 'Maximize',
          onPressed: onMaximizeToggle,
        ),
        _TitleBarCloseButton(
          icon: Icon(Icons.close_rounded, size: 16, color: iconColor),
          tooltip: 'Close',
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _TitleBarButton extends StatefulWidget {
  const _TitleBarButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String tooltip;

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: Material(
          color: _hovered ? colors.onSurface.withValues(alpha: 0.1) : Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.zero,
            splashFactory: NoSplash.splashFactory,
            highlightColor: colors.onSurface.withValues(alpha: 0.15),
            child: SizedBox(
              width: 46,
              height: 40,
              child: Center(child: widget.icon),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBarCloseButton extends StatefulWidget {
  const _TitleBarCloseButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String tooltip;

  @override
  State<_TitleBarCloseButton> createState() => _TitleBarCloseButtonState();
}

class _TitleBarCloseButtonState extends State<_TitleBarCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: Material(
          color: _hovered ? Colors.red.withValues(alpha: 0.85) : Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.zero,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.red.shade700,
            child: SizedBox(
              width: 46,
              height: 40,
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    color: _hovered ? Colors.white : null,
                  ),
                  child: widget.icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
