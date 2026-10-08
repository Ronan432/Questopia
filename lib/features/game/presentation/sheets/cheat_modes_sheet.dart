import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cheat_provider.dart';
import '../../providers/game_engine_provider.dart';

class CheatModesSheet extends ConsumerStatefulWidget {
  const CheatModesSheet({super.key});

  @override
  ConsumerState<CheatModesSheet> createState() => _CheatModesSheetState();
}

class _CheatModesSheetState extends ConsumerState<CheatModesSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addVarController = TextEditingController();
  final TextEditingController _teleportController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _consoleController = TextEditingController();
  String _consoleOutput = '';

  @override
  void dispose() {
    ref.read(cheatProvider.notifier).rollbackIfDirty();
    _searchController.dispose();
    _addVarController.dispose();
    _teleportController.dispose();
    _itemController.dispose();
    _consoleController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cheat = ref.watch(cheatProvider);
    final notifier = ref.read(cheatProvider.notifier);

    return DefaultTabController(
      length: 6,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cheat Engine & Editor',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (cheat.isDirty && !cheat.isSaved)
                      TextButton.icon(
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Keep'),
                        onPressed: () {
                          notifier.markSaved();
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Variables'),
                  Tab(text: 'Locks'),
                  Tab(text: 'Teleport'),
                  Tab(text: 'Inventory'),
                  Tab(text: 'Console'),
                  Tab(text: 'Diff'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _variablesTab(cheat, notifier),
                    _locksTab(cheat, notifier),
                    _teleportTab(notifier),
                    _inventoryTab(notifier),
                    _consoleTab(),
                    _diffTab(cheat),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _variablesTab(CheatState cheat, CheatNotifier notifier) {
    final query = _searchController.text.trim().toLowerCase();
    final vars = query.isEmpty
        ? cheat.watchedVars
        : cheat.watchedVars
            .where((v) => v.name.toLowerCase().contains(query))
            .toList();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addVarController,
                  decoration: const InputDecoration(
                    hintText: 'Variable name...',
                    prefixIcon: Icon(Icons.add_rounded),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    notifier.addWatch(value);
                    _addVarController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Refresh values',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: notifier.refresh,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search watched variables...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: vars.isEmpty
                ? const Center(child: Text('No watched variables'))
                : ListView.builder(
                    itemCount: vars.length,
                    itemBuilder: (context, index) {
                      final v = vars[index];
                      final frozen = cheat.frozen.containsKey(v.name);
                      return ListTile(
                        title: Text(v.name),
                        subtitle: Text(v.displayValue),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: frozen ? 'Unfreeze' : 'Freeze',
                              icon: Icon(
                                frozen
                                    ? Icons.lock_rounded
                                    : Icons.lock_open_outlined,
                              ),
                              onPressed: () => notifier.toggleFreeze(
                                v.name,
                                v.isNumeric
                                    ? v.numValue.toString()
                                    : "'${v.strValue}'",
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _showEditVarDialog(v.name, v.displayValue),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => notifier.removeWatch(v.name),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditVarDialog(String varName, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $varName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Value'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ok = ref
                  .read(cheatProvider.notifier)
                  .setVar(varName, controller.text);
              Navigator.pop(context);
              if (!ok) _showSnack('Engine rejected the value');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _locksTab(CheatState cheat, CheatNotifier notifier) {
    if (cheat.frozen.isEmpty) {
      return const Center(child: Text('No frozen variables active'));
    }
    final entries = cheat.frozen.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          leading: const Icon(Icons.lock_rounded),
          title: Text(entry.key),
          subtitle: Text('Locked to ${entry.value}'),
          trailing: IconButton(
            tooltip: 'Unfreeze',
            icon: const Icon(Icons.lock_open_outlined),
            onPressed: () => notifier.toggleFreeze(entry.key, entry.value),
          ),
        );
      },
    );
  }

  Widget _teleportTab(CheatNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Enter the exact QSP location name to jump to.'),
          const SizedBox(height: 12),
          TextField(
            controller: _teleportController,
            decoration: const InputDecoration(
              hintText: 'Location name...',
              prefixIcon: Icon(Icons.explore_outlined),
            ),
            textInputAction: TextInputAction.go,
            onSubmitted: _doTeleport,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _doTeleport(_teleportController.text),
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Teleport'),
          ),
        ],
      ),
    );
  }

  void _doTeleport(String location) {
    final ok = ref.read(cheatProvider.notifier).teleport(location);
    _showSnack(ok ? 'Teleported to $location' : 'Teleport failed');
  }

  Widget _inventoryTab(CheatNotifier notifier) {
    final engine = ref.watch(gameEngineProvider);
    final objects = engine.gameState.objects;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _itemController,
                  decoration: const InputDecoration(
                    hintText: 'New item name...',
                    prefixIcon: Icon(Icons.add_rounded),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: _doAddItem,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _doAddItem(_itemController.text),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: objects.isEmpty
                ? const Center(child: Text('Inventory is empty'))
                : ListView.builder(
                    itemCount: objects.length,
                    itemBuilder: (context, index) {
                      final item = objects[index];
                      return ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(item.name),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () {
                            final ok = notifier.removeItem(item.name);
                            if (!ok) _showSnack('Could not remove item');
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _doAddItem(String name) {
    if (name.trim().isEmpty) return;
    final ok = ref.read(cheatProvider.notifier).addItem(name);
    if (ok) _itemController.clear();
    _showSnack(ok ? 'Item added' : 'Could not add item');
  }

  Widget _consoleTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _consoleOutput.isEmpty
                      ? 'QSP Console ready.\nEnter statements like: money += 500'
                      : _consoleOutput,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _consoleController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'QSP statement',
              suffixIcon: IconButton(
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: _runConsole,
              ),
            ),
            onSubmitted: (_) => _runConsole(),
          ),
        ],
      ),
    );
  }

  void _runConsole() {
    final code = _consoleController.text.trim();
    if (code.isEmpty) return;
    final ok = ref.read(gameEngineProvider.notifier).execCodeBool(code);
    ref.read(cheatProvider.notifier).refresh();
    setState(() {
      _consoleOutput = '$_consoleOutput\n> $code\n${ok ? 'OK' : 'Failed'}';
    });
    _consoleController.clear();
  }

  Widget _diffTab(CheatState cheat) {
    final diff = cheat.diff;
    if (!cheat.hasSnapshotSave && diff.isEmpty) {
      return const Center(
        child: Text('No snapshot yet. Changes will appear here.'),
      );
    }
    if (diff.isEmpty) {
      return const Center(child: Text('No changes since snapshot'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: diff.length,
      itemBuilder: (context, index) {
        final d = diff[index];
        return ListTile(
          leading: const Icon(Icons.difference_outlined),
          title: Text(d.name),
          subtitle: Text('${d.before}  ->  ${d.after}'),
        );
      },
    );
  }
}
