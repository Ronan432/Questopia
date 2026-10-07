import 'package:flutter/material.dart';

import '../../game/presentation/game_screen.dart';
import '../../settings/presentation/settings_sheet.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({required this.onThemeChanged, super.key});

  final void Function(ThemeMode mode, bool amoled) onThemeChanged;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _tab = 0;
  String _query = '';

  static const _games = [
    _Game('Aşkın Sonu', 'Questopia koleksiyonundaki yerel oyun'),
    _Game('The Return', 'Macera ve keşif'),
    _Game('Northern Lights', 'Uzak katalogdan hazır'),
  ];

  @override
  Widget build(BuildContext context) {
    final shown = _games
        .where(
          (game) => game.title.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questopia'),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) =>
                  SettingsSheet(onThemeChanged: widget.onThemeChanged),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SearchBar(
                hintText: 'Oyunlarda ara',
                leading: const Icon(Icons.search_rounded),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 760
                      ? 3
                      : constraints.maxWidth >= 460
                      ? 2
                      : 1;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: columns == 1 ? 2.6 : .92,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: shown.length,
                    itemBuilder: (context, index) => _GameCard(
                      game: shown[index],
                      onPlay: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => GameScreen(title: shown[index].title),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Kütüphane',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Katalog',
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onPlay});

  final _Game game;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: colors.onSecondaryContainer,
                ),
              ),
              const Spacer(),
              Text(game.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                game.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Başlat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Game {
  const _Game(this.title, this.description);

  final String title;
  final String description;
}
