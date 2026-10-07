import 'dart:ffi';
import 'package:ffi/ffi.dart';

final class QSPStringStruct extends Struct {
  external Pointer<Uint16> str;
  external Pointer<Uint16> end;
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
  /// Allocates UTF-16 uint16 buffer from Dart string.
  static Pointer<Uint16> stringToUtf16(String str) {
    final units = str.codeUnits;
    final ptr = calloc<Uint16>(units.length + 1);
    final nativeList = ptr.asTypedList(units.length + 1);
    for (var i = 0; i < units.length; i++) {
      nativeList[i] = units[i];
    }
    nativeList[units.length] = 0;
    return ptr;
  }

  /// Converts QSPStringStruct or (str, end) pointer pair to Dart String.
  static String qspStringToString(Pointer<Uint16> start, Pointer<Uint16> end) {
    if (start == nullptr || start.address == 0) return '';
    if (end == nullptr || end.address == 0 || end.address <= start.address) {
      // Null-terminated fallback
      final units = <int>[];
      var p = start;
      while (p.value != 0) {
        units.add(p.value);
        p = Pointer.fromAddress(p.address + 2);
      }
      return String.fromCharCodes(units);
    }

    final len = (end.address - start.address) ~/ 2;
    if (len <= 0) return '';
    final units = start.asTypedList(len);
    return String.fromCharCodes(units);
  }

  /// Converts QSPStringStruct value to Dart String.
  static String fromStruct(QSPStringStruct strStruct) {
    return qspStringToString(strStruct.str, strStruct.end);
  }
}
