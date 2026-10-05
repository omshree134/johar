import '../../core/widgets/sign_badge.dart';
import 'ar_task.dart';
import 'localized.dart';

export 'ar_task.dart';

class ModuleContent {
  ModuleContent({
    required this.id,
    required this.sign,
    required this.icon,
    required this.lessons,
    required this.arTasks,
    required this.questions,
    required this.quizSize,
  });

  final String id;
  final SignKind sign;
  final String icon;
  final List<LessonStep> lessons;
  final List<ArTask> arTasks;
  final List<Question> questions;
  final int quizSize;

  factory ModuleContent.fromJson(Map<String, dynamic> j) => ModuleContent(
        id: j['id'] as String,
        sign: signKindFromString(j['sign'] as String),
        icon: j['icon'] as String,
        quizSize: j['quizSize'] as int? ?? 6,
        lessons: [for (final l in j['lessons'] as List) LessonStep.fromJson(l as Map<String, dynamic>)],
        arTasks: [for (final t in j['arTasks'] as List) ArTask.fromJson(t as Map<String, dynamic>)],
        questions: [for (final q in j['questions'] as List) Question.fromJson(q as Map<String, dynamic>)],
      );
}

class LessonStep {
  LessonStep({required this.icon, required this.title, required this.body});
  final String icon;
  final LocalizedText title;
  final LocalizedText body;

  factory LessonStep.fromJson(Map<String, dynamic> j) => LessonStep(
        icon: j['icon'] as String,
        title: parseLocalized(j['title']),
        body: parseLocalized(j['body']),
      );
}

class Question {
  Question({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.critical = false,
  });

  final String id;
  final LocalizedText prompt;
  final List<LocalizedText> options;
  final int correctIndex;
  final LocalizedText explanation;

  /// Life-safety question: must be answered correctly to pass, whatever the score.
  final bool critical;

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as String,
        prompt: parseLocalized(j['prompt']),
        options: [for (final o in j['options'] as List) parseLocalized(o)],
        correctIndex: j['correctIndex'] as int,
        explanation: parseLocalized(j['explanation']),
        critical: j['critical'] as bool? ?? false,
      );
}
