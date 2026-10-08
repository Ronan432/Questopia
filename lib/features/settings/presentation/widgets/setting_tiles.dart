import 'package:flutter/material.dart';

class ColorRow extends StatelessWidget {
  const ColorRow({
    super.key,
    required this.label,
    required this.color,
    required this.onPick,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onPick;

  static const _presets = <Color>[
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFF1C1B1F),
    Color(0xFFE2E2E2),
    Color(0xFFB3261E),
    Color(0xFF0061A4),
    Color(0xFF2E6C38),
    Color(0xFF77539D),
    Color(0xFF924C00),
    Color(0xFF006A6A),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final preset in _presets)
              InkWell(
                onTap: () => onPick(preset),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: preset,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.toARGB32() == preset.toARGB32()
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: color.toARGB32() == preset.toARGB32() ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
