import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/content/module_catalog.dart';
import '../../data/models/module_content.dart';
import '../module/lesson_screen.dart';
import 'assessment_engine.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.module, required this.outcome});
  final ModuleContent module;
  final AssessmentOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final passed = outcome.passed;
    final color = passed ? AppColors.safeGreen : AppColors.fireRed;
    final entry = moduleCatalog.firstWhere((e) => e.id == module.id);
    final syncing = AppScope.of(context).sync.firebaseEnabled;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Icon(passed ? Icons.verified : Icons.replay_circle_filled, size: 72, color: color),
              const SizedBox(height: 20),
              Text(passed ? l.resultPassed : l.resultFailed,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
              const SizedBox(height: 8),
              Text(entry.title(l), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.slate)),
              const SizedBox(height: 24),
              Text(l.yourScore(outcome.totalPercent.round()), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (outcome.criticalMissed.isNotEmpty)
                _Note(icon: Icons.warning_amber, color: AppColors.warningSoft, text: l.criticalMissed),
              if (passed && syncing)
                _Note(icon: Icons.cloud_upload_outlined, color: AppColors.manganeseSoft, text: l.certificateOnTheWay),
              const Spacer(),
              if (!passed) ...[
                FilledButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(builder: (_) => LessonScreen(entry: entry)),
                  ),
                  child: Text(l.tryAgain),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(l.backHome)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.coal),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
