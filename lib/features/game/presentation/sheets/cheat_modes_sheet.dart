import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../core/helpers/dialog_helper.dart';
import '../../../../core/helpers/sheet_helper.dart';
import '../../../../core/helpers/sheet_ui_helper.dart';
import '../../providers/cheat_provider.dart';
import '../../providers/game_engine_provider.dart';
import 'helpers/cheat_sheet_actions.dart';
import 'helpers/cheat_sheet_views.dart';

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
  int _activeTabIndex = 0;

  static const _tabTitles = [
    'Variables',
    'Locks',
    'Teleport',
    'Inventory',
    'Console',
    'Diff',
  ];

  static const _tabIcons = [
    Icons.data_object_rounded,
    Icons.lock_outline_rounded,
    Icons.explore_outlined,
    Icons.inventory_2_outlined,
    Icons.terminal_rounded,
    Icons.difference_outlined,
  ];

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

  @override
  Widget build(BuildContext context) {
    final cheat = ref.watch(cheatProvider);
    final notifier = ref.read(cheatProvider.notifier);
    final engineState = ref.watch(gameEngineProvider);

    return QuestopiaSheetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const QuestopiaSheetHeaderPill(title: 'Cheat Engine and Editor'),
          const SizedBox(height: 12),

          // Category Tabs Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _tabTitles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(_tabIcons[i], size: 16),
                    label: Text(_tabTitles[i]),
                    selected: _activeTabIndex == i,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(_activeTabIndex == i ? 24 : 8),
                    ),
                    onSelected: (_) {
                      HapticFeedback.lightImpact();
                      setState(() => _activeTabIndex = i);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tab Content Body
          Expanded(
            child: IndexedStack(
              index: _activeTabIndex,
              children: [
                CheatVariablesView(
                  cheat: cheat,
                  notifier: notifier,
                  searchController: _searchController,
                  addVarController: _addVarController,
                  onSearchChanged: () => setState(() {}),
                  onEditVar: _showEditVarDialog,
                ),
                CheatLocksView(cheat: cheat, notifier: notifier),
                CheatTeleportView(
                  controller: _teleportController,
                  onTeleport: _doTeleport,
                ),
                CheatInventoryView(
                  engineState: engineState,
                  notifier: notifier,
                  itemController: _itemController,
                  onAddItem: _doAddItem,
                ),
                CheatConsoleView(
                  consoleController: _consoleController,
                  consoleOutput: _consoleOutput,
                  onRunConsole: _runConsole,
                ),
                CheatDiffView(cheat: cheat),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditVarDialog(String varName, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    final colors = Theme.of(context).colorScheme;

    showQuestopiaDialog<void>(
      context: context,
      builder: (ctx) => QuestopiaDialog(
        icon: const Icon(Icons.edit_note_rounded),
        title: Text('Edit $varName'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'New Value',
            filled: true,
            fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        actions: [
          M3EButton(
            onPressed: () => Navigator.pop(ctx),
            style: M3EButtonStyle.text,
            size: M3EButtonSize.md,
            child: const Text('Cancel'),
          ),
          M3EButton(
            onPressed: () {
              final ok = ref
                  .read(cheatProvider.notifier)
                  .setVar(varName, controller.text);
              Navigator.pop(ctx);
              if (!ok) showSheetSnackBar(context, 'Engine rejected the value');
            },
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.md,
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _doTeleport(String location) {
    final ok = ref.read(cheatProvider.notifier).teleport(location);
    showSheetSnackBar(context, ok ? 'Teleported to $location' : 'Teleport failed');
  }

  void _doAddItem(String name) {
    if (name.trim().isEmpty) return;
    final ok = ref.read(cheatProvider.notifier).addItem(name);
    if (ok) _itemController.clear();
    showSheetSnackBar(context, ok ? 'Item added' : 'Could not add item');
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
}
