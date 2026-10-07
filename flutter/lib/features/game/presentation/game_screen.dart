import 'package:flutter/material.dart';

import 'sheets/cheat_modes_sheet.dart';
import 'sheets/save_slots_sheet.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({required this.title, super.key});

  final String title;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String _description =
      'Oyun başlatılmaya hazır. QSP motoru yüklendiğinde ana açıklama burada görüntülenir.';
  final List<String> _actions = [
    'Devam et',
    'Envanteri incele',
    'Haritaya bak',
  ];

  Future<void> _showMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_outlined),
                title: const Text('Kaydet ve yükle'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet<void>(
                    context: this.context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const SaveSlotsSheet(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Hile modları'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet<void>(
                    context: this.context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const CheatModesSheet(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt_rounded),
                title: const Text('Yeniden başlat'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _description = 'Oyun yeniden başlatıldı.');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _showMenu,
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Oyun seçenekleri',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _description,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(height: 1.55),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _actions
                    .map(
                      (action) => FilledButton.tonal(
                        onPressed: () => setState(
                          () => _description =
                              '$action seçildi. QSP eylemi yürütüldüğünde sonuç burada güncellenir.',
                        ),
                        child: Text(action),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Komut veya yanıt girin',
                  prefixIcon: Icon(Icons.keyboard_alt_outlined),
                ),
                onSubmitted: (value) =>
                    setState(() => _description = 'Girdi alındı: $value'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
