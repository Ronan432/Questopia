import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

/// Helper functions returning [SegmentedListTile] for settings lists.
class SettingsTiles {
  const SettingsTiles._();

  static SegmentedListTile navTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    Color? leadingDot,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SegmentedListTile(
      leading: Icon(icon, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: leadingDot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
      minVerticalPadding: 18,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  static SegmentedListTile switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SegmentedListTile(
      leading: Icon(icon, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: M3ESwitch(
        value: value,
        selectedIcon: const Icon(Icons.check, size: 16),
        onChanged: (val) {
          HapticFeedback.lightImpact();
          onChanged(val);
        },
      ),
      minVerticalPadding: 18,
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
    );
  }

  static SegmentedListTile sliderTile({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    int? divisions,
  }) {
    return SegmentedListTile(
      leading: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(icon, size: 24),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              trackShape: const RoundedRectSliderTrackShape(),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
      minVerticalPadding: 16,
    );
  }
}
