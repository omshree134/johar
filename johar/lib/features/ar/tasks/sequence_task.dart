import '../../../data/models/ar_task.dart';
import '../../assessment/assessment_engine.dart';
import 'task_controller.dart';

/// Steps placed around the worker; they must act on them in the right order.
/// Used for evacuation sequencing, lockout-tagout and buddy rescue.
/// Items with no `order` are wrong actions (e.g. "climb in to help").
class SequenceTask extends TaskController {
  SequenceTask(super.task);

  final List<String> done = [];
  final Set<String> wrongIds = {};
  int mistakes = 0;

  int get totalSteps => objects.where((o) => o.order != null).length;

  @override
  bool isSelectable(SceneObject o) => o.kind == SceneObjectKind.item;

  /// Step number shown on the marker once done (1-based), else null.
  int? stepNumber(SceneObject o) {
    final i = done.indexOf(o.id);
    return i < 0 ? null : i + 1;
  }

  @override
  MarkerState stateOf(SceneObject o) {
    if (done.contains(o.id)) return MarkerState.correct;
    if (wrongIds.contains(o.id)) return MarkerState.wrong;
    return MarkerState.idle;
  }

  @override
  void select(SceneObject o) {
    if (finished || done.contains(o.id)) return;
    if (o.order != null && o.order == done.length + 1) {
      done.add(o.id);
      if (o.info.isNotEmpty) showInfo(o.info, good: true, seconds: 2.5);
      if (done.length == totalSteps) _finish(TaskOutcome.done);
    } else {
      mistakes++;
      if (o.order == null) wrongIds.add(o.id);
      if (o.order == null && o.info.isNotEmpty) {
        showInfo(o.info, good: false);
      } else {
        showHint(HudHint.wrongOrder);
      }
    }
    notifyListeners();
  }

  void _finish(TaskOutcome outcome) => finish(
        AssessmentEngine.scoreSequence(
          steps: totalSteps,
          mistakes: mistakes,
          completed: done.length == totalSteps,
        ),
        outcome,
      );

  @override
  void onTimeUp() => _finish(TaskOutcome.timeUp);
}
