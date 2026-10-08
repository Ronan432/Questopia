import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String kCrashReportFileName = 'crash_report.txt';

/// Captures uncaught Flutter/framework errors to a file so the next launch
/// can offer the report, mirroring the legacy crash report dialog.
final class CrashReporter {
  CrashReporter._();

  static bool _installed = false;

  static Future<File> _reportFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, kCrashReportFileName));
  }

  static void install() {
    if (_installed) return;
    _installed = true;
    final previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterOnError?.call(details);
      _persist(
        'FlutterError: ${details.exceptionAsString()}\n${details.stack ?? ''}',
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _persist('Uncaught: $error\n$stack');
      return true;
    };
  }

  static Future<void> _persist(String text) async {
    try {
      final file = await _reportFile();
      final stamped = '[${DateTime.now().toIso8601String()}]\n$text\n\n';
      await file.writeAsString(stamped, mode: FileMode.append);
    } catch (_) {
      // Reporting must never crash the app.
    }
  }

  static Future<String?> takePendingReport() async {
    try {
      final file = await _reportFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      await file.delete();
      return content;
    } catch (_) {
      return null;
    }
  }
}
