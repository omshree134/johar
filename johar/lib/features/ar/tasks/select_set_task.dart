import '../../../data/models/ar_task.dart';
import '../../assessment/assessment_engine.dart';
import 'task_controller.dart';

/// Items (e.g. PPE) placed in an arc around the worker; wider than one
/// screen, so they turn to see everything. Tap to pick, then Check.
class SelectSetTask extends TaskController {
  SelectSetTask(super.task);

  final Set<String> selected = {};

  @override
  bool isSelectable(SceneObject o) => o.kind == SceneObjectKind.item;

  @override
  MarkerState stateOf(SceneObject o) {
    final picked = selected.contains(o.id);
    if (!finished) return picked ? MarkerState.selected : MarkerState.idle;
    if (o.correct) return MarkerState.correct;
    return picked ? MarkerState.wrong : MarkerState.idle;
  }

  @override
  void select(SceneObject o) {
    if (finished || !isSelectable(o)) return;
    if (!selected.remove(o.id)) selected.add(o.id);
    notifyListeners();
  }

  void check([TaskOutcome outcome = TaskOutcome.done]) {
    final items = objects.where(isSelectable);
    finish(
      AssessmentEngine.scoreSelectSet(
        correctTotal: items.where((i) => i.correct).length,
        correctPicked: items.where((i) => i.correct && selected.contains(i.id)).length,
        wrongPicked: items.where((i) => !i.correct && selected.contains(i.id)).length,
      ),
      outcome,
    );
  }

  @override
  void onTimeUp() => check(TaskOutcome.timeUp);
}
