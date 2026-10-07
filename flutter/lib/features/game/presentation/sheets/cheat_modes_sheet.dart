import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_engine_provider.dart';

class CheatModesSheet extends ConsumerStatefulWidget {
  const CheatModesSheet({super.key});

  @override
  ConsumerState<CheatModesSheet> createState() => _CheatModesSheetState();
}

class _CheatModesSheetState extends ConsumerState<CheatModesSheet> {
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _commandController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cheat Engine & Editor',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
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
                    _variablesTab(),
                    _message('No frozen variables active'),
                    _message('Select target QSP location'),
                    _message('Inventory items list'),
                    _consoleTab(),
                    _message('Initial state snapshot taken'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _variablesTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search variable name...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('money'),
                  subtitle: const Text('1000'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showEditVarDialog('money', '1000'),
                  ),
                ),
                ListTile(
                  title: const Text('health'),
                  subtitle: const Text('100'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showEditVarDialog('health', '100'),
                  ),
                ),
                ListTile(
                  title: const Text(r'$location'),
                  subtitle: const Text('StartLocation'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showEditVarDialog(r'$location', "'StartLocation'"),
                  ),
                ),
              ],
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
              ref
                  .read(gameEngineProvider.notifier)
                  .overrideVariable(varName, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
              child: const SingleChildScrollView(
                child: Text(
                  'QSP Console ready.\nEnter statements like: money += 500 or goto "loc2"',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commandController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'QSP statement',
              suffixIcon: IconButton(
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: () {
                  if (_commandController.text.trim().isNotEmpty) {
                    ref
                        .read(gameEngineProvider.notifier)
                        .execCode(_commandController.text.trim());
                    _commandController.clear();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(String value) => Center(child: Text(value));
}
