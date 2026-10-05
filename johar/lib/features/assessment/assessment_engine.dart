import 'dart:math';
import '../../core/config/cert_keys.dart';
import '../../data/models/module_content.dart';

/// A question prepared for one attempt, with its options shuffled.
class QuizItem {
  QuizItem(this.question, this.optionOrder);
  final Question question;

  /// optionOrder[i] = index into question.options shown at position i.
  final List<int> optionOrder;

  int get correctPosition => optionOrder.indexOf(question.correctIndex);
}

class AssessmentOutcome {
  AssessmentOutcome({
    required this.quizPercent,
    required this.arPercent,
    required this.totalPercent,
    required this.passed,
    required this.criticalMissed,
    required this.wrongQuestionIds,
  });

  final double quizPercent;
  final double arPercent;
  final double totalPercent;
  final bool passed;
  final List<String> criticalMissed;
  final List<String> wrongQuestionIds;
}

/// Pure Dart, no Flutter imports: fully unit-testable.
///
/// Scoring rules:
///  * Total = 60% quiz + 40% hands-on AR tasks (quiz only if a module has no tasks).
///  * Pass needs total >= kPassMark AND every critical (life-safety) question correct.
///  * Critical questions always appear in the quiz; the rest are drawn at random,
///    so two workers sharing a phone do not see the same test.
class AssessmentEngine {
  AssessmentEngine({Random? random}) : _rng = random ?? Random();

  static const double quizWeight = 0.6;
  static const double arWeight = 0.4;
  final Random _rng;

  List<QuizItem> buildQuiz(ModuleContent module) {
    final critical = module.questions.where((q) => q.critical).toList();
    final others = module.questions.where((q) => !q.critical).toList()..shuffle(_rng);
    final size = max(module.quizSize, critical.length);
    final chosen = [...critical, ...others.take(max(0, size - critical.length))]..shuffle(_rng);
    return [
      for (final q in chosen) QuizItem(q, List<int>.generate(q.options.length, (i) => i)..shuffle(_rng)),
    ];
  }

  /// [answers] holds the chosen position per quiz item (null = unanswered).
  /// [arScores] maps task id -> score between 0 and 1.
  AssessmentOutcome evaluate({
    required ModuleContent module,
    required List<QuizItem> quiz,
    required List<int?> answers,
    required Map<String, double> arScores,
  }) {
    assert(answers.length == quiz.length);
    var correct = 0;
    final wrong = <String>[];
    final criticalMissed = <String>[];
    for (var i = 0; i < quiz.length; i++) {
      final item = quiz[i];
      if (answers[i] == item.correctPosition) {
        correct++;
      } else {
        wrong.add(item.question.id);
        if (item.question.critical) criticalMissed.add(item.question.id);
      }
    }
    final quizPct = quiz.isEmpty ? 0.0 : correct / quiz.length * 100;

    final hasAr = module.arTasks.isNotEmpty;
    final arPct = hasAr
        ? module.arTasks.map((t) => (arScores[t.id] ?? 0.0).clamp(0.0, 1.0).toDouble()).reduce((a, b) => a + b) /
            module.arTasks.length *
            100
        : 0.0;

    final total = hasAr ? quizPct * quizWeight + arPct * arWeight : quizPct;
    return AssessmentOutcome(
      quizPercent: _round(quizPct),
      arPercent: _round(arPct),
      totalPercent: _round(total),
      passed: total >= kPassMark && criticalMissed.isEmpty,
      criticalMissed: criticalMissed,
      wrongQuestionIds: wrong,
    );
  }

  // ---- AR task scoring (0..1) ----

  /// Full marks for the right target first time, half after one mistake.
  static double scoreIdentify({required bool foundCorrect, required int wrongTaps}) {
    if (!foundCorrect) return 0;
    return switch (wrongTaps) { 0 => 1.0, 1 => 0.5, _ => 0.25 };
  }

  /// Each wrong tap removes one step's worth of marks.
  static double scoreSequence({required int steps, required int mistakes, required bool completed}) {
    if (steps == 0) return 0;
    final base = completed ? 1.0 : 0.5;
    return (base - mistakes / steps).clamp(0.0, 1.0).toDouble();
  }

  /// Correct picks minus wrong picks, over the number of correct items.
  static double scoreSelectSet({required int correctTotal, required int correctPicked, required int wrongPicked}) {
    if (correctTotal == 0) return 0;
    return ((correctPicked - wrongPicked) / correctTotal).clamp(0.0, 1.0).toDouble();
  }

  static double _round(double v) => (v * 10).round() / 10;
}
