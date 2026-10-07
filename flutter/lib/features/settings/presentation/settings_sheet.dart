import 'package:flutter/material.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({required this.onThemeChanged, super.key});

  final void Function(ThemeMode mode, bool amoled) onThemeChanged;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  ThemeMode _mode = ThemeMode.system;
  bool _amoled = false;
  double _fontScale = 1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text('Ayarlar', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
                ButtonSegment(value: ThemeMode.light, label: Text('Açık')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Koyu')),
              ],
              selected: {_mode},
              onSelectionChanged: (value) {
                setState(() => _mode = value.first);
                widget.onThemeChanged(_mode, _amoled);
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('AMOLED siyahı'),
              value: _amoled,
              onChanged: (value) {
                setState(() => _amoled = value);
                widget.onThemeChanged(_mode, _amoled);
              },
            ),
            const SizedBox(height: 8),
            Text('Yazı boyutu  ${_fontScale.toStringAsFixed(1)}x'),
            Slider(
              value: _fontScale,
              min: .8,
              max: 1.4,
              divisions: 6,
              onChanged: (value) => setState(() => _fontScale = value),
            ),
            const ListTile(
              leading: Icon(Icons.folder_outlined),
              title: Text('Oyun klasörü'),
              subtitle: Text('Cihazınızdaki oyun dizinini seçin'),
            ),
            const ListTile(
              leading: Icon(Icons.volume_up_outlined),
              title: Text('Ses ve medya'),
              subtitle: Text('Ses seviyesi, OGV ve yakınlaştırma'),
            ),
          ],
        ),
      ),
    );
  }
}
