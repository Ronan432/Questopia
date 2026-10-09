import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/crash_reporter.dart';
import '../../../../core/helpers/dialog_helper.dart';

/// Helper to display previous crash reports if any occurred.
class CrashDialogHelper {
  const CrashDialogHelper._();

  static Future<void> offerCrashReport(BuildContext context) async {
    final report = await CrashReporter.takePendingReport();
    if (!context.mounted || report == null) return;
    final preview =
        report.length > 800 ? '${report.substring(0, 800)}...' : report;

    await showQuestopiaDialog<void>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return QuestopiaDialog(
          icon: Icon(Icons.bug_report_rounded, color: colors.error),
          title: const Text('Previous Session Crashed'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Questopia encountered an unhandled error in the last run. You can copy the diagnostic details below to report it.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  preview,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
          actions: [
            QuestopiaMorphButton.outlined(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            QuestopiaMorphButton.filled(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: report));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Crash log copied to clipboard'),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              child: const Text('Copy Details'),
            ),
          ],
        );
      },
    );
  }
}
