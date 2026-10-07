import 'dart:ffi';
import 'dart:io';

class QspFfi {
  QspFfi._(this._library);

  final DynamicLibrary _library;

  static QspFfi? tryLoad() {
    try {
      if (Platform.isAndroid) {
        return QspFfi._(DynamicLibrary.open('libqsp.so'));
      }
      if (Platform.isWindows) {
        return QspFfi._(DynamicLibrary.open('qsp.dll'));
      }
    } on ArgumentError {
      return null;
    }
    return null;
  }

  bool get isAvailable => _library.providesSymbol('QSPInit');

  void init() =>
      _library.lookupFunction<Void Function(), void Function()>('QSPInit')();

  void dispose() =>
      _library.lookupFunction<Void Function(), void Function()>('QSPDeInit')();
}
