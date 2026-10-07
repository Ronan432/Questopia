import 'dart:ffi';
import 'dart:io';

class RustRuntime {
  RustRuntime._(this.library);

  final DynamicLibrary library;

  static RustRuntime? tryLoad() {
    try {
      if (Platform.isAndroid) {
        return RustRuntime._(DynamicLibrary.open('libquestopia_rust.so'));
      }
      if (Platform.isWindows) {
        return RustRuntime._(DynamicLibrary.open('questopia_rust.dll'));
      }
    } on ArgumentError {
      return null;
    }
    return null;
  }
}
