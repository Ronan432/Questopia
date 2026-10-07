import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
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
    Int32 Function(Int32 index, Int32 toRefreshUI);
typedef NativeQSPExecuteSelActionCode = Int32 Function(Int32 toRefreshUI);

typedef NativeQSPGetObjects =
    Int32 Function(Pointer<QSPListItemStruct> items, Int32 bufSize);
typedef NativeQSPSetSelObjectIndex =
    Int32 Function(Int32 index, Int32 toRefreshUI);

typedef NativeQSPExecString =
    Int32 Function(QSPStringStruct str, Int32 toRefreshUI);
typedef NativeQSPLoadGameWorldFromData =
    Int32 Function(Pointer<Uint8> data, Int32 size, Int32 isNewGame);
typedef NativeQSPOpenSavedGameFromData =
    Int32 Function(Pointer<Uint8> data, Int32 size, Int32 toRefreshUI);
typedef NativeQSPSaveGameAsData = Int32 Function(
    Pointer<Uint8> buf, Pointer<Int32> bufSize, Int32 toRefreshUI);
typedef NativeQSPRestartGame = Int32 Function(Int32 toRefreshUI);
typedef NativeQSPGetLastErrorData = QSPErrorInfoStruct Function();

typedef NativeQSPGetVarValue = Int32 Function(QSPStringStruct name,
    Int32 index, Pointer<Void> variantRes); // Simplified for primitive lookup
typedef NativeQSPGetNumVarValue = Int32 Function(
    QSPStringStruct name, Int32 index, Pointer<Int64> res);
typedef NativeQSPGetStrVarValue = Int32 Function(
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

typedef DartQSPGetNumVarValue = int Function(
    QSPStringStruct name, int index, Pointer<Int64> res);
typedef DartQSPGetStrVarValue = int Function(
    QSPStringStruct name, int index, Pointer<QSPStringStruct> res);

class QspFfi {
  QspFfi._(this._library) {
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
      _getNumVarValue = _library.lookupFunction<NativeQSPGetNumVarValue,
          DartQSPGetNumVarValue>('QSPGetNumVarValue');
      _getStrVarValue = _library.lookupFunction<NativeQSPGetStrVarValue,
          DartQSPGetStrVarValue>('QSPGetStrVarValue');
    } catch (_) {
      // Optional features
    }
  }

  final DynamicLibrary _library;

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

  DartQSPGetNumVarValue? _getNumVarValue;
  DartQSPGetStrVarValue? _getStrVarValue;

  static QspFfi? instance;

  static QspFfi? tryLoad() {
    if (instance != null) return instance;
    try {
      if (Platform.isAndroid) {
        instance = QspFfi._(DynamicLibrary.open('libqsp.so'));
        return instance;
      }
      if (Platform.isWindows) {
        instance = QspFfi._(DynamicLibrary.open('qsp.dll'));
        return instance;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  bool get isAvailable => _library.providesSymbol('QSPInit');

  void init() {
    _init();
  }

  void dispose() {
    _terminate();
  }

  String getVersion() {
    final s = _getVersion();
    return QspUtf16.fromStruct(s);
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
    final res = _setSelActionIndex(index, refresh ? 1 : 0);
    if (res == 0) return false;
    return _executeSelActionCode(refresh ? 1 : 0) != 0;
  }

  bool selectObject(int index, {bool refresh = true}) {
    return _setSelObjectIndex(index, refresh ? 1 : 0) != 0;
  }

  bool execString(String code, {bool refresh = true}) {
    final ptr = QspUtf16.stringToUtf16(code);
    final strStruct = calloc<QSPStringStruct>();
    try {
      strStruct.ref.str = ptr;
      strStruct.ref.end = Pointer.fromAddress(ptr.address + code.length * 2);
      return _execString(strStruct.ref, refresh ? 1 : 0) != 0;
    } finally {
      calloc.free(ptr);
      calloc.free(strStruct);
    }
  }

  bool loadGameData(Uint8List data, {bool isNew = true}) {
    final ptr = calloc<Uint8>(data.length);
    try {
      ptr.asTypedList(data.length).setAll(0, data);
      return _loadGameWorldFromData(ptr, data.length, isNew ? 1 : 0) != 0;
    } finally {
      calloc.free(ptr);
    }
  }

  bool openSaveData(Uint8List data, {bool refresh = true}) {
    final ptr = calloc<Uint8>(data.length);
    try {
      ptr.asTypedList(data.length).setAll(0, data);
      return _openSavedGameFromData(ptr, data.length, refresh ? 1 : 0) != 0;
    } finally {
      calloc.free(ptr);
    }
  }

  Uint8List? saveGameData({bool refresh = true}) {
    final initialSize = 512 * 1024;
    final bufPtr = calloc<Uint8>(initialSize);
    final sizePtr = calloc<Int32>();
    try {
      sizePtr.value = initialSize;
      final ok = _saveGameAsData(bufPtr, sizePtr, refresh ? 1 : 0) != 0;
      if (!ok) return null;
      final size = sizePtr.value;
      return Uint8List.fromList(bufPtr.asTypedList(size));
    } finally {
      calloc.free(bufPtr);
      calloc.free(sizePtr);
    }
  }

  bool restartGame({bool refresh = true}) {
    return _restartGame(refresh ? 1 : 0) != 0;
  }

  QspErrorInfo getLastError() {
    final err = _getLastErrorData();
    return QspErrorInfo(
      errorNum: err.errorNum,
      errorDesc: QspUtf16.fromStruct(err.errorDesc),
      locName: QspUtf16.fromStruct(err.locName),
      actIndex: err.actIndex,
      lineNum: err.intLineNum,
      codeLine: QspUtf16.fromStruct(err.intLine),
    );
  }

  int getVarNum(String name, [int index = 0]) {
    if (_getNumVarValue == null) return 0;
    final ptr = QspUtf16.stringToUtf16(name);
    final nameStruct = calloc<QSPStringStruct>();
    final resPtr = calloc<Int64>();
    try {
      nameStruct.ref.str = ptr;
      nameStruct.ref.end = Pointer.fromAddress(ptr.address + name.length * 2);
      final ok = _getNumVarValue!(nameStruct.ref, index, resPtr) != 0;
      if (!ok) return 0;
      return resPtr.value;
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
      if (!ok) return '';
      return QspUtf16.fromStruct(resStruct.ref);
    } finally {
      calloc.free(ptr);
      calloc.free(nameStruct);
      calloc.free(resStruct);
    }
  }
}
