import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/native/qsp_models.dart';
import 'game_engine_provider.dart';

class CheatVar {
  const CheatVar({
    required this.name,
    this.numValue = 0,
    this.strValue = '',
    this.isNumeric = true,
  });

  final String name;
  final int numValue;
  final String strValue;
  final bool isNumeric;

  String get displayValue => isNumeric ? numValue.toString() : strValue;

  CheatVar copyWith({int? numValue, String? strValue, bool? isNumeric}) {
    return CheatVar(
      name: name,
      numValue: numValue ?? this.numValue,
      strValue: strValue ?? this.strValue,
      isNumeric: isNumeric ?? this.isNumeric,
    );
  }
}

class VarDiff {
  const VarDiff({
    required this.name,
    required this.before,
    required this.after,
  });

  final String name;
  final String before;
  final String after;
}

class CheatState {
  const CheatState({
    this.watchedVars = const [],
    this.frozen = const {},
    this.snapshotVars = const [],
    this.hasSnapshotSave = false,
    this.isSaved = false,
    this.isDirty = false,
  });

  final List<CheatVar> watchedVars;
  final Map<String, String> frozen;
  final List<CheatVar> snapshotVars;
  final bool hasSnapshotSave;
  final bool isSaved;
  final bool isDirty;

  List<VarDiff> get diff {
    final before = {for (final v in snapshotVars) v.name: v.displayValue};
    final result = <VarDiff>[];
    for (final current in watchedVars) {
      final old = before[current.name];
      if (old != null) {
        if (old != current.displayValue) {
          result.add(VarDiff(
            name: current.name,
            before: old,
            after: current.displayValue,
          ));
        }
      }
    }
    return result;
  }

  CheatState copyWith({
    List<CheatVar>? watchedVars,
    Map<String, String>? frozen,
    List<CheatVar>? snapshotVars,
    bool? hasSnapshotSave,
    bool? isSaved,
    bool? isDirty,
  }) {
    return CheatState(
      watchedVars: watchedVars ?? this.watchedVars,
      frozen: frozen ?? this.frozen,
      snapshotVars: snapshotVars ?? this.snapshotVars,
      hasSnapshotSave: hasSnapshotSave ?? this.hasSnapshotSave,
      isSaved: isSaved ?? this.isSaved,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

/// Engine access seam: the default implementation talks to the live
/// [GameEngineNotifier]; tests inject a fake.
abstract interface class VarBackend {
  int getNum(String name);
  String getStr(String name);
  bool exec(String code);
  Uint8List? save();
  bool load(Uint8List data);
  List<QspObject> objects();
  List<String> getDiscoveredVars();
}

final class EngineVarBackend implements VarBackend {
  EngineVarBackend(this._engine);

  final GameEngineNotifier _engine;

  @override
  int getNum(String name) => _engine.readVarNum(name);

  @override
  String getStr(String name) => _engine.readVarStr(name);

  @override
  bool exec(String code) => _engine.execCodeBool(code);

  @override
  Uint8List? save() => _engine.takeSaveSnapshot();

  @override
  bool load(Uint8List data) => _engine.restoreSaveSnapshot(data);

  @override
  List<QspObject> objects() => _engine.currentObjects();

  @override
  List<String> getDiscoveredVars() => _engine.getDiscoveredVarNames();
}

class CheatNotifier extends StateNotifier<CheatState> {
  CheatNotifier(this._backend, [List<String>? initialWatches])
      : super(const CheatState()) {
    if (initialWatches != null) {
      for (final name in initialWatches) {
        addWatch(name);
      }
    }
    scanDiscoveredVariables();
    takeSnapshot();
  }

  final VarBackend _backend;
  Uint8List? _snapshotSave;

  static String _escape(String value) => value.replaceAll("'", "''");

  CheatVar _readVar(String name) {
    final str = _backend.getStr(name);
    if (str.isNotEmpty) {
      return CheatVar(name: name, strValue: str, isNumeric: false);
    }
    return CheatVar(name: name, numValue: _backend.getNum(name));
  }

  void _enforceFrozen() {
    for (final entry in state.frozen.entries) {
      _backend.exec("${entry.key} = ${entry.value}");
    }
  }

  bool _execAndEnforce(String code) {
    final ok = _backend.exec(code);
    _enforceFrozen();
    refresh();
    return ok;
  }

  void scanDiscoveredVariables() {
    final discovered = _backend.getDiscoveredVars();
    final currentNames = {for (final v in state.watchedVars) v.name.toLowerCase()};
    final newVars = <CheatVar>[];
    for (final name in discovered) {
      if (!currentNames.contains(name.toLowerCase())) {
        final v = _readVar(name);
        newVars.add(v);
        currentNames.add(name.toLowerCase());
      }
    }
    if (newVars.isNotEmpty) {
      state = state.copyWith(
        watchedVars: [...state.watchedVars, ...newVars],
      );
    }
  }

  void refresh() {
    scanDiscoveredVariables();
    state = state.copyWith(
      watchedVars: [
        for (final v in state.watchedVars) _readVar(v.name),
      ],
    );
  }

  void addWatch(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (state.watchedVars.any((v) => v.name == trimmed)) return;
    state = state.copyWith(
      watchedVars: [...state.watchedVars, _readVar(trimmed)],
    );
  }

  void removeWatch(String name) {
    state = state.copyWith(
      watchedVars: [
        for (final v in state.watchedVars)
          if (v.name != name) v,
      ],
    );
  }

  bool setVar(String name, String value) {
    final ok = _execAndEnforce("$name = $value");
    if (ok) state = state.copyWith(isDirty: true);
    return ok;
  }

  void toggleFreeze(String name, String frozenValue) {
    final frozen = Map<String, String>.from(state.frozen);
    if (frozen.containsKey(name)) {
      frozen.remove(name);
    } else {
      frozen[name] = frozenValue;
    }
    state = state.copyWith(frozen: frozen, isDirty: true);
    _enforceFrozen();
    refresh();
  }

  bool teleport(String location) {
    final loc = location.trim();
    if (loc.isEmpty) return false;
    final ok = _execAndEnforce("goto '${_escape(loc)}'");
    if (ok) state = state.copyWith(isDirty: true);
    return ok;
  }

  bool addItem(String itemName) {
    final item = itemName.trim();
    if (item.isEmpty) return false;
    final ok = _execAndEnforce("addobj '${_escape(item)}'");
    if (ok) state = state.copyWith(isDirty: true);
    return ok;
  }

  bool removeItem(String itemName) {
    final ok = _execAndEnforce("delobj '${_escape(itemName.trim())}'");
    if (ok) state = state.copyWith(isDirty: true);
    return ok;
  }

  void takeSnapshot() {
    _snapshotSave = _backend.save();
    state = state.copyWith(
      snapshotVars: List.of(state.watchedVars),
      hasSnapshotSave: _snapshotSave != null,
    );
  }

  bool rollbackIfDirty() {
    if (!state.isDirty || state.isSaved) return false;
    var ok = false;
    if (_snapshotSave != null) {
      ok = _backend.load(_snapshotSave!);
    }
    for (final v in state.snapshotVars) {
      _backend.exec(
          "${v.name} = ${v.isNumeric ? v.numValue : "'${_escape(v.strValue)}'"}");
    }
    refresh();
    return ok;
  }

  void markSaved() {
    state = state.copyWith(isSaved: true);
  }
}

final cheatProvider =
    StateNotifierProvider.autoDispose<CheatNotifier, CheatState>((ref) {
  final engine = ref.watch(gameEngineProvider.notifier);
  return CheatNotifier(EngineVarBackend(engine));
});
