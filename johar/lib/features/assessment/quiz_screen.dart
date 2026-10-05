import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_scope.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/services/ar_capability_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/attempt_record.dart';
import '../../data/models/certificate_record.dart';
import '../../data/models/localized.dart';
import '../../data/models/module_content.dart';
import '../certificate/certificate_codec.dart';
import 'assessment_engine.dart';
import 'result_screen.dart';

/// One question per screen. After each answer the worker sees whether it was
/// right and why, so the test also teaches.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.module, required this.arScores, required this.startedAt});
  final ModuleContent module;
  final Map<String, double> arScores;
  final DateTime startedAt;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _engine = AssessmentEngine();
  late final List<QuizItem> _quiz = _engine.buildQuiz(widget.module);
  late final List<int?> _answers = List<int?>.filled(_quiz.length, null);
  int _index = 0;
  int? _picked;
  bool _checked = false;
  bool _saving = false;

  Future<void> _finish() async {
    setState(() => _saving = true);
    final scope = AppScope.of(context);
    final worker = scope.store.activeWorker!;
    final outcome = _engine.evaluate(
      module: widget.module,
      quiz: _quiz,
      answers: _answers,
      arScores: widget.arScores,
    );
    final mode = await ArCapabilityService.effectiveMode();
    final attemptId = const Uuid().v4();
    final now = DateTime.now();

    await scope.store.addAttempt(AttemptRecord(
      id: attemptId,
      workerId: worker.id,
      moduleId: widget.module.id,
      quizPercent: outcome.quizPercent,
      arPercent: outcome.arPercent,
      totalPercent: outcome.totalPercent,
      passed: outcome.passed,
      criticalMissed: outcome.criticalMissed,
      wrongQuestionIds: outcome.wrongQuestionIds,
      startedAt: widget.startedAt,
      completedAt: now,
      arMode: mode.name,
    ));

    // Immediately issue genuine signed certificate if passed
    if (outcome.passed) {
      final issuedAt = now;
      final expiresAt = now.add(const Duration(days: 365));
      final token = await CertificateCodec.generateToken(
        certId: attemptId,
        workerId: worker.id,
        workerName: worker.name,
        employeeId: worker.employeeId,
        moduleId: widget.module.id,
        score: outcome.totalPercent.round(),
        issuedAt: issuedAt,
        expiresAt: expiresAt,
      );
      if (token != null) {
        await scope.store.upsertCertificates([
          CertificateRecord(
            certId: attemptId,
            workerId: worker.id,
            moduleId: widget.module.id,
            token: token,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            status: 'active',
          ),
        ]);
      }
    }

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => ResultScreen(module: widget.module, outcome: outcome)),
    );
  }

  void _primaryAction() {
    if (!_checked) {
      setState(() {
        _answers[_index] = _picked;
        _checked = true;
      });
    } else if (_index < _quiz.length - 1) {
      setState(() {
        _index++;
        _picked = null;
        _checked = false;
      });
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = AppScope.of(context).localeController.contentLang;
    final item = _quiz[_index];
    final q = item.question;
    final isLast = _index == _quiz.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text(l.questionOf(_index + 1, _quiz.length))),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_index + (_checked ? 1 : 0)) / _quiz.length,
              minHeight: 6,
              backgroundColor: AppColors.line,
              color: AppColors.manganese,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(tr(q.prompt, lang), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  for (var pos = 0; pos < item.optionOrder.length; pos++) ...[
                    _OptionCard(
                      text: tr(q.options[item.optionOrder[pos]], lang),
                      state: _optionState(pos, item),
                      onTap: _checked ? null : () => setState(() => _picked = pos),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_checked) ...[
                    const SizedBox(height: 8),
                    _Explanation(
                      correct: _picked == item.correctPosition,
                      title: _picked == item.correctPosition ? l.taskCorrect : null,
                      text: tr(q.explanation, lang),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton(
                onPressed: (_picked == null || _saving) ? null : _primaryAction,
                child: Text(!_checked ? l.checkAnswer : (isLast ? l.seeResult : l.next)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _OptState _optionState(int pos, QuizItem item) {
    if (!_checked) return pos == _picked ? _OptState.selected : _OptState.idle;
    if (pos == item.correctPosition) return _OptState.correct;
    if (pos == _picked) return _OptState.wrong;
    return _OptState.idle;
  }
}

enum _OptState { idle, selected, correct, wrong }

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.text, required this.state, required this.onTap});
  final String text;
  final _OptState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, icon) = switch (state) {
      _OptState.idle => (AppColors.surface, AppColors.line, Icons.circle_outlined),
      _OptState.selected => (AppColors.manganeseSoft, AppColors.manganese, Icons.radio_button_checked),
      _OptState.correct => (AppColors.safeGreenSoft, AppColors.safeGreen, Icons.check_circle),
      _OptState.wrong => (AppColors.fireRedSoft, AppColors.fireRed, Icons.cancel),
    };
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border, width: state == _OptState.idle ? 1 : 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: state == _OptState.idle ? AppColors.slate : border),
              const SizedBox(width: 14),
              Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({required this.correct, required this.text, this.title});
  final bool correct;
  final String text;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: correct ? AppColors.safeGreenSoft : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(correct ? Icons.check_circle : Icons.lightbulb_outline,
              color: correct ? AppColors.safeGreen : AppColors.coal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) Text(title!, style: Theme.of(context).textTheme.titleMedium),
                Text(text, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
