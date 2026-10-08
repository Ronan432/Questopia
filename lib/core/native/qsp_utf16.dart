import 'dart:ffi';
import 'package:ffi/ffi.dart';

final class QSPStringStruct extends Struct {
  external Pointer<Uint8> str;
  external Pointer<Uint8> end;
}

final class QSPListItemStruct extends Struct {
  external QSPStringStruct image;
  external QSPStringStruct name;
}

final class QSPErrorInfoStruct extends Struct {
  @Int32()
  external int errorNum;

  external QSPStringStruct errorDesc;
  external QSPStringStruct locName;

  @Int32()
  external int actIndex;

  @Int32()
  external int topLineNum;

  @Int32()
  external int intLineNum;

  external QSPStringStruct intLine;
}

class QspUtf16 {
  /// Global native wchar width in bytes (2 for UTF-16, 4 for UTF-32).
  static int nativeWcharSize = 2;

  /// Sets and calibrates the native wchar size.
  static void setWcharSize(int size) {
    if (size == 2 || size == 4) {
      nativeWcharSize = size;
    }
  }

  /// Allocates native wchar buffer from Dart string matching native wchar size.
  static Pointer<Uint8> stringToNative(String str) {
    final codeUnits = str.codeUnits;
    if (nativeWcharSize == 4) {
      final ptr = calloc<Uint32>(codeUnits.length + 1);
      final nativeList = ptr.asTypedList(codeUnits.length + 1);
      for (var i = 0; i < codeUnits.length; i++) {
        nativeList[i] = codeUnits[i];
      }
      nativeList[codeUnits.length] = 0;
      return ptr.cast<Uint8>();
    } else {
      final ptr = calloc<Uint16>(codeUnits.length + 1);
      final nativeList = ptr.asTypedList(codeUnits.length + 1);
      for (var i = 0; i < codeUnits.length; i++) {
        nativeList[i] = codeUnits[i];
      }
      nativeList[codeUnits.length] = 0;
      return ptr.cast<Uint8>();
    }
  }

  /// Backward-compatible alias for stringToNative.
  static Pointer<Uint8> stringToUtf16(String str) => stringToNative(str);

  /// Populates a [QSPStringStruct] from an allocated buffer and Dart string.
  static void populateStruct(
      QSPStringStruct strStruct, Pointer<Uint8> ptr, String text) {
    strStruct.str = ptr;
    strStruct.end =
        Pointer.fromAddress(ptr.address + text.length * nativeWcharSize);
  }

  /// Converts QSPStringStruct or (str, end) pointer pair to Dart String.
  static String qspStringToString(Pointer<Uint8> start, Pointer<Uint8> end) {
    if (start == nullptr || start.address == 0) return '';

    // Auto-detect 4-byte vs 2-byte if distance allows
    var charWidth = nativeWcharSize;
    if (end != nullptr && end.address > start.address) {
      final byteLen = end.address - start.address;
      if (byteLen % 4 == 0 && byteLen >= 4) {
        final u16 = start.cast<Uint16>();
        if (u16[1] == 0 && u16[0] != 0) {
          charWidth = 4;
        }
      } else if (byteLen % 2 == 0) {
        charWidth = 2;
      }
    }

    if (end == nullptr || end.address == 0 || end.address <= start.address) {
      final charCodes = <int>[];
      if (charWidth == 4) {
        var p = start.cast<Uint32>();
        while (p.value != 0) {
          charCodes.add(p.value);
          p = Pointer.fromAddress(p.address + 4);
        }
      } else {
        var p = start.cast<Uint16>();
        while (p.value != 0) {
          charCodes.add(p.value);
          p = Pointer.fromAddress(p.address + 2);
        }
      }
      return String.fromCharCodes(charCodes);
    }

    final byteLen = end.address - start.address;
    final charCount = byteLen ~/ charWidth;
    if (charCount <= 0) return '';

    if (charWidth == 4) {
      final u32List = start.cast<Uint32>().asTypedList(charCount);
      return String.fromCharCodes(u32List);
    } else {
      final u16List = start.cast<Uint16>().asTypedList(charCount);
      return String.fromCharCodes(u16List);
    }
  }

  /// Converts QSPStringStruct value to Dart String.
  static String fromStruct(QSPStringStruct strStruct) {
    return qspStringToString(strStruct.str, strStruct.end);
  }
}
