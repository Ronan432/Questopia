import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:questopia_re/core/native/qsp_models.dart';
import 'package:questopia_re/features/game/providers/cheat_provider.dart';

final class FakeVarBackend implements VarBackend {
  FakeVarBackend({
    Map<String, int>? nums,
    Map<String, String>? strs,
    Uint8List? saveData,
  })  : nums = nums ?? {},
        strs = strs ?? {},
        saveData = saveData ?? Uint8List.fromList([9, 9]);

  final Map<String, int> nums;
  final Map<String, String> strs;
  final Uint8List saveData;
  final List<String> executed = [];
  Uint8List? loaded;

  @override
  int getNum(String name) => nums[name] ?? 0;

  @override
  String getStr(String name) => strs[name] ?? '';

  @override
  bool exec(String code) {
    executed.add(code);
    return true;
  }

  @override
  Uint8List? save() => saveData;

  @override
  bool load(Uint8List data) {
    loaded = data;
    return true;
  }

  @override
  List<QspObject> objects() => const [];
}

void main() {
  group('CheatNotifier', () {
    test('reads numeric and string variables', () {
      final backend = FakeVarBackend(
        nums: {'money': 1000},
        strs: {'name': 'Hero'},
      );
      final notifier = CheatNotifier(backend, ['money', 'name']);
      final vars = notifier.state.watchedVars;
      expect(vars, hasLength(2));
      expect(vars[0].displayValue, '1000');
      expect(vars[1].displayValue, 'Hero');
      expect(vars[1].isNumeric, isFalse);
      notifier.dispose();
    });

    test('setVar executes and marks dirty', () {
      final backend = FakeVarBackend(nums: {'money': 1000});
      final notifier = CheatNotifier(backend, ['money']);
      expect(notifier.setVar('money', '500'), isTrue);
      expect(backend.executed, contains('money = 500'));
      expect(notifier.state.isDirty, isTrue);
      notifier.dispose();
    });

    test('freeze toggles and re-applies after writes', () {
      final backend = FakeVarBackend(nums: {'money': 1000});
      final notifier = CheatNotifier(backend, ['money']);
      notifier.toggleFreeze('money', '1000');
      expect(notifier.state.frozen, {'money': '1000'});
      notifier.setVar('money', '5');
      expect(backend.executed.last, 'money = 1000');
      notifier.toggleFreeze('money', '1000');
      expect(notifier.state.frozen, isEmpty);
      notifier.dispose();
    });

    test('teleport and inventory use QSP statements', () {
      final backend = FakeVarBackend();
      final notifier = CheatNotifier(backend);
      expect(notifier.teleport('Town'), isTrue);
      expect(backend.executed, contains("goto 'Town'"));
      expect(notifier.addItem('Key'), isTrue);
      expect(backend.executed, contains("addobj 'Key'"));
      expect(notifier.removeItem('Key'), isTrue);
      expect(backend.executed, contains("delobj 'Key'"));
      expect(notifier.teleport('  '), isFalse);
      notifier.dispose();
    });

    test('rollback restores the snapshot save and variables', () {
      final backend = FakeVarBackend(
        nums: {'money': 100},
        strs: {'name': 'Hero'},
      );
      final notifier = CheatNotifier(backend, ['money', 'name']);
      notifier.setVar('money', '999');
      expect(notifier.rollbackIfDirty(), isTrue);
      expect(backend.loaded, backend.saveData);
      expect(
        backend.executed,
        contains('money = 100'),
      );
      expect(
        backend.executed,
        contains("name = 'Hero'"),
      );
      notifier.dispose();
    });

    test('markSaved prevents rollback', () {
      final backend = FakeVarBackend(nums: {'money': 100});
      final notifier = CheatNotifier(backend, ['money']);
      notifier.setVar('money', '5');
      notifier.markSaved();
      expect(notifier.rollbackIfDirty(), isFalse);
      expect(backend.loaded, isNull);
      notifier.dispose();
    });

    test('diff reports changed watched variables', () {
      final backend = FakeVarBackend(nums: {'money': 100});
      final notifier = CheatNotifier(backend, ['money']);
      expect(notifier.state.diff, isEmpty);
      backend.nums['money'] = 250;
      notifier.refresh();
      final diff = notifier.state.diff;
      expect(diff, hasLength(1));
      expect(diff.first.name, 'money');
      expect(diff.first.before, '100');
      expect(diff.first.after, '250');
      notifier.dispose();
    });
  });
}
