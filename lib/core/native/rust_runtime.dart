import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef NativeRustParseHtml = Pointer<Utf8> Function(Pointer<Utf8> input);
typedef DartRustParseHtml = Pointer<Utf8> Function(Pointer<Utf8> input);

typedef NativeRustParseRepoXml = Pointer<Utf8> Function(Pointer<Utf8> input);
typedef DartRustParseRepoXml = Pointer<Utf8> Function(Pointer<Utf8> input);

typedef NativeRustExtractArchive = Int32 Function(
    Pointer<Utf8> archivePath, Pointer<Utf8> targetDir);
typedef DartRustExtractArchive = int Function(
    Pointer<Utf8> archivePath, Pointer<Utf8> targetDir);

typedef NativeRustFreeString = Void Function(Pointer<Utf8> ptr);
typedef DartRustFreeString = void Function(Pointer<Utf8> ptr);

class RustRuntime {
  RustRuntime._(this.library) {
    try {
      _parseHtml =
          library.lookupFunction<NativeRustParseHtml, DartRustParseHtml>(
              'rust_parse_html');
      _parseRepoXml =
          library.lookupFunction<NativeRustParseRepoXml, DartRustParseRepoXml>(
              'rust_parse_repository_xml');
      _extractArchive = library.lookupFunction<NativeRustExtractArchive,
          DartRustExtractArchive>('rust_extract_archive');
      _freeString =
          library.lookupFunction<NativeRustFreeString, DartRustFreeString>(
              'rust_free_string');
    } catch (_) {
      // Functions will be null if not exported
    }
  }

  final DynamicLibrary library;

  DartRustParseHtml? _parseHtml;
  DartRustParseRepoXml? _parseRepoXml;
  DartRustExtractArchive? _extractArchive;
  DartRustFreeString? _freeString;

  static RustRuntime? instance;

  static RustRuntime? tryLoad() {
    if (instance != null) return instance;
    try {
      if (Platform.isAndroid) {
        instance = RustRuntime._(DynamicLibrary.open('libquestopia_rust.so'));
        return instance;
      }
      if (Platform.isWindows) {
        instance = RustRuntime._(DynamicLibrary.open('questopia_rust.dll'));
        return instance;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String? parseHtml(String input) {
    if (_parseHtml == null || _freeString == null) return null;
    final cInput = input.toNativeUtf8();
    try {
      final resPtr = _parseHtml!(cInput);
      if (resPtr == nullptr) return null;
      final result = resPtr.toDartString();
      _freeString!(resPtr);
      return result;
    } finally {
      calloc.free(cInput);
    }
  }

  String? parseRepositoryXml(String xmlInput) {
    if (_parseRepoXml == null || _freeString == null) return null;
    final cInput = xmlInput.toNativeUtf8();
    try {
      final resPtr = _parseRepoXml!(cInput);
      if (resPtr == nullptr) return null;
      final result = resPtr.toDartString();
      _freeString!(resPtr);
      return result;
    } finally {
      calloc.free(cInput);
    }
  }

  int extractArchive(String archivePath, String targetDir) {
    if (_extractArchive == null) return -1;
    final cArchive = archivePath.toNativeUtf8();
    final cTarget = targetDir.toNativeUtf8();
    try {
      return _extractArchive!(cArchive, cTarget);
    } finally {
      calloc.free(cArchive);
      calloc.free(cTarget);
    }
  }
}
