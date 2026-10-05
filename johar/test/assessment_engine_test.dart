import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:johar/core/widgets/sign_badge.dart';
import 'package:johar/data/models/module_content.dart';
import 'package:johar/features/assessment/assessment_engine.dart';

Question q(String id, {bool critical = false}) => Question(
      id: id,
      prompt: const {'en': ''},
      options: const [{'en': 'right'}, {'en': 'wrong'}, {'en': 'also wrong'}],
      correctIndex: 0,
      explanation: const {'en': ''},
      critical: critical,
    );

ModuleContent module({int quizSize = 4, bool withAr = true}) => ModuleContent(
      id: 'test',
      sign: SignKind.warning,
      icon: 'gas',
      quizSize: quizSize,
      lessons: const [],
      arTasks: withAr
          ? const [
              ArTask(
                id: 't1',
                type: ArTaskType.findHazards,
                prompt: <String, String>{},
                feedback: <String, String>{},
                timeLimitSec: 10,
                objects: <SceneObject>[],
              ),
            ]
          : const [],
      questions: [q('c1', critical: true), q('c2', critical: true), q('a'), q('b'), q('c'), q('d')],
    );

List<int?> answerAll(List<QuizItem> quiz, {Set<String> wrong = const {}}) => [
      for (final item in quiz)
        wrong.contains(item.question.id) ? (item.correctPosition + 1) % 3 : item.correctPosition,
    ];

void main() {
  late AssessmentEngine engine;

  setUp(() {
    engine = AssessmentEngine(random: Random(42));
  });

  test('critical questions are always included', () {
    for (var i = 0; i < 20; i++) {
      final ids = engine.buildQuiz(module()).map((e) => e.question.id).toSet();
      expect(ids, containsAll(['c1', 'c2']));
      expect(ids.length, 4);
    }
  });

  test('option shuffling keeps track of the correct answer', () {
    for (final item in engine.buildQuiz(module())) {
      expect(item.optionOrder[item.correctPosition], item.question.correctIndex);
    }
  });

  test('all correct passes with full marks', () {
    final m = module();
    final quiz = engine.buildQuiz(m);
    final out = engine.evaluate(module: m, quiz: quiz, answers: answerAll(quiz), arScores: {'t1': 1});
    expect(out.totalPercent, 100);
    expect(out.passed, isTrue);
  });

  test('missing a critical question fails even with a high score', () {
    final m = module(quizSize: 6);
    final quiz = engine.buildQuiz(m);
    final out = engine.evaluate(module: m, quiz: quiz, answers: answerAll(quiz, wrong: {'c1'}), arScores: {'t1': 1});
    expect(out.totalPercent, greaterThan(80));
    expect(out.passed, isFalse);
    expect(out.criticalMissed, ['c1']);
  });

  test('score is 60% quiz and 40% AR', () {
    final m = module();
    final quiz = engine.buildQuiz(m);
    final out = engine.evaluate(module: m, quiz: quiz, answers: answerAll(quiz), arScores: {'t1': 0});
    expect(out.totalPercent, 60);
    expect(out.passed, isFalse);
  });

  test('AR task scoring helpers', () {
    expect(AssessmentEngine.scoreIdentify(foundCorrect: true, wrongTaps: 0), 1);
    expect(AssessmentEngine.scoreIdentify(foundCorrect: true, wrongTaps: 1), 0.5);
    expect(AssessmentEngine.scoreIdentify(foundCorrect: false, wrongTaps: 0), 0);
    expect(AssessmentEngine.scoreSelectSet(correctTotal: 4, correctPicked: 4, wrongPicked: 1), 0.75);
    expect(AssessmentEngine.scoreSelectSet(correctTotal: 2, correctPicked: 0, wrongPicked: 2), 0);
  });
}
