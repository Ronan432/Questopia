import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

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
      builder: (ctx) => QuestopiaDialog(
        icon: const Icon(Icons.bug_report_rounded),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                preview,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          M3EButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: M3EButtonStyle.text,
            size: M3EButtonSize.md,
            child: const Text('Dismiss'),
          ),
          M3EButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Crash log copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Details'),
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.md,
          ),
        ],
      ),
    );
  }
}
