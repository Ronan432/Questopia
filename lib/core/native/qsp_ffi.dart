import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'qsp_models.dart';
import 'qsp_utf16.dart';

// Native typedefs
typedef NativeQSPInit = Void Function();
typedef NativeQSPTerminate = Void Function();
typedef NativeQSPGetVersion = QSPStringStruct Function();
typedef NativeQSPGetMainDesc = QSPStringStruct Function();
typedef NativeQSPGetVarsDesc = QSPStringStruct Function();

typedef NativeQSPGetActions =
    Int32 Function(Pointer<QSPListItemStruct> items, Int32 bufSize);
typedef NativeQSPSetSelActionIndex =
    Int8 Function(Int32 index, Int32 toRefreshUI);
typedef NativeQSPExecuteSelActionCode = Int8 Function(Int32 toRefreshUI);

typedef NativeQSPGetObjects =
    Int32 Function(Pointer<QSPListItemStruct> items, Int32 bufSize);
typedef NativeQSPSetSelObjectIndex =
    Int8 Function(Int32 index, Int32 toRefreshUI);

typedef NativeQSPExecString =
    Int8 Function(QSPStringStruct str, Int32 toRefreshUI);
typedef NativeQSPLoadGameWorldFromData =
    Int8 Function(Pointer<Uint8> data, Int32 size, Int32 isNewGame);
typedef NativeQSPOpenSavedGameFromData =
    Int8 Function(Pointer<Uint8> data, Int32 size, Int32 toRefreshUI);
typedef NativeQSPSaveGameAsData = Int8 Function(
    Pointer<Uint8> buf, Pointer<Int32> bufSize, Int32 toRefreshUI);
typedef NativeQSPRestartGame = Int8 Function(Int32 toRefreshUI);
typedef NativeQSPGetLastErrorData = QSPErrorInfoStruct Function();
typedef NativeQSPSetCallback = Void Function(
    Int32, Pointer<NativeFunction<Int64 Function()>>);
typedef NativeQSPExecCounter = Int8 Function(Int32 toRefreshUI);

typedef NativeQSPGetVarValue = Int32 Function(QSPStringStruct name,
    Int32 index, Pointer<Void> variantRes); // Simplified for primitive lookup
typedef NativeQSPGetNumVarValue = Int8 Function(
    QSPStringStruct name, Int32 index, Pointer<Int32> res);
typedef NativeQSPGetStrVarValue = Int8 Function(
    QSPStringStruct name, Int32 index, Pointer<QSPStringStruct> res);

// Dart typedefs
typedef DartQSPInit = void Function();
typedef DartQSPTerminate = void Function();
typedef DartQSPGetVersion = QSPStringStruct Function();
typedef DartQSPGetMainDesc = QSPStringStruct Function();
typedef DartQSPGetVarsDesc = QSPStringStruct Function();

typedef DartQSPGetActions = int Function(
    Pointer<QSPListItemStruct> items, int bufSize);
typedef DartQSPSetSelActionIndex = int Function(int index, int toRefreshUI);
typedef DartQSPExecuteSelActionCode = int Function(int toRefreshUI);

typedef DartQSPGetObjects = int Function(
    Pointer<QSPListItemStruct> items, int bufSize);
typedef DartQSPSetSelObjectIndex = int Function(int index, int toRefreshUI);

typedef DartQSPExecString = int Function(
    QSPStringStruct str, int toRefreshUI);
typedef DartQSPLoadGameWorldFromData = int Function(
    Pointer<Uint8> data, int size, int isNewGame);
typedef DartQSPOpenSavedGameFromData = int Function(
    Pointer<Uint8> data, int size, int toRefreshUI);
typedef DartQSPSaveGameAsData = int Function(
    Pointer<Uint8> buf, Pointer<Int32> bufSize, int toRefreshUI);
typedef DartQSPRestartGame = int Function(int toRefreshUI);
typedef DartQSPGetLastErrorData = QSPErrorInfoStruct Function();
typedef DartQSPSetCallback = void Function(
    int, Pointer<NativeFunction<Int64 Function()>>);
typedef DartQSPExecCounter = int Function(int toRefreshUI);

typedef DartQSPGetNumVarValue = int Function(
    QSPStringStruct name, int index, Pointer<Int32> res);
typedef DartQSPGetStrVarValue = int Function(
    QSPStringStruct name, int index, Pointer<QSPStringStruct> res);

class QspFfi {
  QspFfi._(this._library) {
    debugPrint('[QSP FFI] Binding functions from dynamic library...');
    _init = _library.lookupFunction<NativeQSPInit, DartQSPInit>('QSPInit');
    _terminate = _library.lookupFunction<NativeQSPTerminate, DartQSPTerminate>(
        'QSPTerminate');
    _getVersion = _library
        .lookupFunction<NativeQSPGetVersion, DartQSPGetVersion>('QSPGetVersion');
    _getMainDesc =
        _library.lookupFunction<NativeQSPGetMainDesc, DartQSPGetMainDesc>(
            'QSPGetMainDesc');
    _getVarsDesc =
        _library.lookupFunction<NativeQSPGetVarsDesc, DartQSPGetVarsDesc>(
            'QSPGetVarsDesc');

    _getActions =
        _library.lookupFunction<NativeQSPGetActions, DartQSPGetActions>(
            'QSPGetActions');
    _setSelActionIndex = _library.lookupFunction<NativeQSPSetSelActionIndex,
        DartQSPSetSelActionIndex>('QSPSetSelActionIndex');
    _executeSelActionCode = _library.lookupFunction<
        NativeQSPExecuteSelActionCode,
        DartQSPExecuteSelActionCode>('QSPExecuteSelActionCode');

    _getObjects =
        _library.lookupFunction<NativeQSPGetObjects, DartQSPGetObjects>(
            'QSPGetObjects');
    _setSelObjectIndex = _library.lookupFunction<NativeQSPSetSelObjectIndex,
        DartQSPSetSelObjectIndex>('QSPSetSelObjectIndex');

    _execString = _library
        .lookupFunction<NativeQSPExecString, DartQSPExecString>('QSPExecString');
    _loadGameWorldFromData = _library.lookupFunction<
        NativeQSPLoadGameWorldFromData,
        DartQSPLoadGameWorldFromData>('QSPLoadGameWorldFromData');
    _openSavedGameFromData = _library.lookupFunction<
        NativeQSPOpenSavedGameFromData,
        DartQSPOpenSavedGameFromData>('QSPOpenSavedGameFromData');
    _saveGameAsData = _library.lookupFunction<NativeQSPSaveGameAsData,
        DartQSPSaveGameAsData>('QSPSaveGameAsData');
    _restartGame = _library
        .lookupFunction<NativeQSPRestartGame, DartQSPRestartGame>('QSPRestartGame');
    _getLastErrorData = _library.lookupFunction<NativeQSPGetLastErrorData,
        DartQSPGetLastErrorData>('QSPGetLastErrorData');

    try {
      _setCallback = _library.lookupFunction<NativeQSPSetCallback,
          DartQSPSetCallback>('QSPSetCallback');
      debugPrint('[QSP FFI] QSPSetCallback successfully resolved.');
    } catch (_) {
      debugPrint('[QSP FFI] QSPSetCallback symbol unavailable.');
    }
    try {
      _execCounter = _library.lookupFunction<NativeQSPExecCounter,
          DartQSPExecCounter>('QSPExecCounter');
      debugPrint('[QSP FFI] QSPExecCounter successfully resolved.');
    } catch (_) {
      debugPrint('[QSP FFI] QSPExecCounter symbol unavailable.');
    }

    try {
      _getNumVarValue = _library.lookupFunction<NativeQSPGetNumVarValue,
          DartQSPGetNumVarValue>('QSPGetNumVarValue');
      _getStrVarValue = _library.lookupFunction<NativeQSPGetStrVarValue,
          DartQSPGetStrVarValue>('QSPGetStrVarValue');
      debugPrint('[QSP FFI] QSPGetNumVarValue & QSPGetStrVarValue resolved.');
    } catch (_) {
      debugPrint('[QSP FFI] Var lookup symbols unavailable.');
    }
  }

  final DynamicLibrary _library;

  DynamicLibrary get nativeLibrary => _library;

  late final DartQSPInit _init;
  late final DartQSPTerminate _terminate;
  late final DartQSPGetVersion _getVersion;
  late final DartQSPGetMainDesc _getMainDesc;
  late final DartQSPGetVarsDesc _getVarsDesc;
  late final DartQSPGetActions _getActions;
  late final DartQSPSetSelActionIndex _setSelActionIndex;
  late final DartQSPExecuteSelActionCode _executeSelActionCode;
  late final DartQSPGetObjects _getObjects;
  late final DartQSPSetSelObjectIndex _setSelObjectIndex;
  late final DartQSPExecString _execString;
  late final DartQSPLoadGameWorldFromData _loadGameWorldFromData;
  late final DartQSPOpenSavedGameFromData _openSavedGameFromData;
  late final DartQSPSaveGameAsData _saveGameAsData;
  late final DartQSPRestartGame _restartGame;
  late final DartQSPGetLastErrorData _getLastErrorData;
  DartQSPSetCallback? _setCallback;
  DartQSPExecCounter? _execCounter;

  DartQSPGetNumVarValue? _getNumVarValue;
  DartQSPGetStrVarValue? _getStrVarValue;

  static QspFfi? instance;

  static QspFfi? tryLoad() {
    if (instance != null) {
      return instance;
    }
    try {
      if (Platform.isAndroid) {
        debugPrint('[QSP FFI] Opening libqsp.so on Android...');
        instance = QspFfi._(DynamicLibrary.open('libqsp.so'));
        return instance;
      }
      if (Platform.isWindows) {
        debugPrint('[QSP FFI] Opening qsp.dll on Windows...');
        instance = QspFfi._(DynamicLibrary.open('qsp.dll'));
        return instance;
      }
    } catch (e, st) {
      debugPrint('[QSP FFI] Error opening native library: $e\n$st');
      return null;
    }
    debugPrint('[QSP FFI] Unsupported platform: ${Platform.operatingSystem}');
    return null;
  }

  bool get isAvailable => _library.providesSymbol('QSPInit');

  void init() {
    debugPrint('[QSP FFI] Calling QSPInit()...');
    _init();
  }

  void dispose() {
    debugPrint('[QSP FFI] Calling QSPTerminate()...');
    _terminate();
  }

  String getVersion() {
    final s = _getVersion();
    final ver = QspUtf16.fromStruct(s);
    debugPrint('[QSP FFI] QSPGetVersion() => "$ver"');
    return ver;
  }

  String getMainDesc() {
    final s = _getMainDesc();
    return QspUtf16.fromStruct(s);
  }

  String getVarsDesc() {
    final s = _getVarsDesc();
    return QspUtf16.fromStruct(s);
  }

  List<QspAction> getActions() {
    final bufSize = 256;
    final itemsPtr = calloc<QSPListItemStruct>(bufSize);
    try {
      final count = _getActions(itemsPtr, bufSize);
      final actions = <QspAction>[];
      for (var i = 0; i < count; i++) {
        final item = itemsPtr[i];
        final name = QspUtf16.fromStruct(item.name);
        final image = QspUtf16.fromStruct(item.image);
        actions.add(QspAction(index: i, name: name, image: image));
      }
      return actions;
    } finally {
      calloc.free(itemsPtr);
    }
  }

  List<QspObject> getObjects() {
    final bufSize = 256;
    final itemsPtr = calloc<QSPListItemStruct>(bufSize);
    try {
      final count = _getObjects(itemsPtr, bufSize);
      final objects = <QspObject>[];
      for (var i = 0; i < count; i++) {
        final item = itemsPtr[i];
        final name = QspUtf16.fromStruct(item.name);
        final image = QspUtf16.fromStruct(item.image);
        objects.add(QspObject(index: i, name: name, image: image));
      }
      return objects;
    } finally {
      calloc.free(itemsPtr);
    }
  }

  bool executeAction(int index, {bool refresh = true}) {
    debugPrint('[QSP FFI] executeAction(index: $index, refresh: $refresh)');
    final res = _setSelActionIndex(index, refresh ? 1 : 0);
    if (res == 0) {
      debugPrint('[QSP FFI] QSPSetSelActionIndex($index) failed');
      return false;
    }
    final ok = _executeSelActionCode(refresh ? 1 : 0) != 0;
    debugPrint('[QSP FFI] QSPExecuteSelActionCode() => $ok');
    return ok;
  }

  bool selectObject(int index, {bool refresh = true}) {
    debugPrint('[QSP FFI] selectObject(index: $index, refresh: $refresh)');
    final ok = _setSelObjectIndex(index, refresh ? 1 : 0) != 0;
    debugPrint('[QSP FFI] QSPSetSelObjectIndex() => $ok');
    return ok;
  }

  bool execString(String code, {bool refresh = true}) {
    debugPrint('[QSP FFI] execString("$code", refresh: $refresh)');
    final ptr = QspUtf16.stringToUtf16(code);
    final strStruct = calloc<QSPStringStruct>();
    try {
      strStruct.ref.str = ptr;
      strStruct.ref.end = Pointer.fromAddress(ptr.address + code.length * 2);
      final ok = _execString(strStruct.ref, refresh ? 1 : 0) != 0;
      debugPrint('[QSP FFI] QSPExecString() => $ok');
      return ok;
    } finally {
      calloc.free(ptr);
      calloc.free(strStruct);
    }
  }

  bool loadGameData(Uint8List data, {bool isNew = true}) {
    debugPrint('[QSP FFI] loadGameData(size: ${data.length} bytes, isNew: $isNew)');
    final ptr = calloc<Uint8>(data.length);
    try {
      ptr.asTypedList(data.length).setAll(0, data);
      final ok = _loadGameWorldFromData(ptr, data.length, isNew ? 1 : 0) != 0;
      debugPrint('[QSP FFI] QSPLoadGameWorldFromData() => $ok');
      return ok;
    } finally {
      calloc.free(ptr);
    }
  }

  bool openSaveData(Uint8List data, {bool refresh = true}) {
    debugPrint('[QSP FFI] openSaveData(size: ${data.length} bytes, refresh: $refresh)');
    final ptr = calloc<Uint8>(data.length);
    try {
      ptr.asTypedList(data.length).setAll(0, data);
      final ok = _openSavedGameFromData(ptr, data.length, refresh ? 1 : 0) != 0;
      debugPrint('[QSP FFI] QSPOpenSavedGameFromData() => $ok');
      return ok;
    } finally {
      calloc.free(ptr);
    }
  }

  Uint8List? saveGameData({bool refresh = true}) {
    debugPrint('[QSP FFI] saveGameData(refresh: $refresh)');
    final initialSize = 512 * 1024;
    final bufPtr = calloc<Uint8>(initialSize);
    final sizePtr = calloc<Int32>();
    try {
      sizePtr.value = initialSize;
      final ok = _saveGameAsData(bufPtr, sizePtr, refresh ? 1 : 0) != 0;
      if (!ok) {
        debugPrint('[QSP FFI] QSPSaveGameAsData() failed');
        return null;
      }
      final size = sizePtr.value;
      debugPrint('[QSP FFI] QSPSaveGameAsData() succeeded, size: $size bytes');
      return Uint8List.fromList(bufPtr.asTypedList(size));
    } finally {
      calloc.free(bufPtr);
      calloc.free(sizePtr);
    }
  }

  bool restartGame({bool refresh = true}) {
    debugPrint('[QSP FFI] restartGame(refresh: $refresh)');
    final ok = _restartGame(refresh ? 1 : 0) != 0;
    debugPrint('[QSP FFI] QSPRestartGame() => $ok');
    return ok;
  }

  bool get supportsCallbacks => _setCallback != null;

  void setCallback(
      int type, Pointer<NativeFunction<Int64 Function()>> func) {
    debugPrint('[QSP FFI] setCallback(type: $type)');
    _setCallback?.call(type, func);
  }

  bool execCounter({bool refresh = true}) {
    final exec = _execCounter;
    if (exec == null) return false;
    return exec(refresh ? 1 : 0) != 0;
  }

  QspErrorInfo getLastError() {
    final err = _getLastErrorData();
    final info = QspErrorInfo(
      errorNum: err.errorNum,
      errorDesc: QspUtf16.fromStruct(err.errorDesc),
      locName: QspUtf16.fromStruct(err.locName),
      actIndex: err.actIndex,
      lineNum: err.intLineNum,
      codeLine: QspUtf16.fromStruct(err.intLine),
    );
    if (info.errorNum != 0) {
      debugPrint('[QSP FFI] getLastError() => $info');
    }
    return info;
  }

  int getVarNum(String name, [int index = 0]) {
    if (_getNumVarValue == null) return 0;
    final ptr = QspUtf16.stringToUtf16(name);
    final nameStruct = calloc<QSPStringStruct>();
    final resPtr = calloc<Int32>();
    try {
      nameStruct.ref.str = ptr;
      nameStruct.ref.end = Pointer.fromAddress(ptr.address + name.length * 2);
      final ok = _getNumVarValue!(nameStruct.ref, index, resPtr) != 0;
      return ok ? resPtr.value : 0;
    } finally {
      calloc.free(ptr);
      calloc.free(nameStruct);
      calloc.free(resPtr);
    }
  }

  String getVarStr(String name, [int index = 0]) {
    if (_getStrVarValue == null) return '';
    final ptr = QspUtf16.stringToUtf16(name);
    final nameStruct = calloc<QSPStringStruct>();
    final resStruct = calloc<QSPStringStruct>();
    try {
      nameStruct.ref.str = ptr;
      nameStruct.ref.end = Pointer.fromAddress(ptr.address + name.length * 2);
      final ok = _getStrVarValue!(nameStruct.ref, index, resStruct) != 0;
      return ok ? QspUtf16.fromStruct(resStruct.ref) : '';
    } finally {
      calloc.free(ptr);
      calloc.free(nameStruct);
      calloc.free(resStruct);
    }
  }
}
