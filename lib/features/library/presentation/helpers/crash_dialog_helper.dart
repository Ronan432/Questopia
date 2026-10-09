import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/crash_reporter.dart';

/// Helper to display previous crash reports if any occurred.
class CrashDialogHelper {
  const CrashDialogHelper._();

  static Future<void> offerCrashReport(BuildContext context) async {
    final report = await CrashReporter.takePendingReport();
    if (!context.mounted || report == null) return;
    final preview =
        report.length > 800 ? '${report.substring(0, 800)}...' : report;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Previous Session Crashed'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Questopia encountered an unhandled error in the last run. You can copy the diagnostic details below to report it.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  preview,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Crash log copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy Details'),
          ),
        ],
      ),
    );
  }
}
