import '../../../data/models/ar_task.dart';
import 'task_controller.dart';

/// "Spot the hazard": hazards and safe decoys are placed all around the
/// worker, so they must physically turn and scan the whole area.
/// Score = (hazards found - 0.25 per safe item wrongly flagged) / hazards.
class FindHazardsTask extends TaskController {
  FindHazardsTask(super.task);

  final Set<String> found = {};
  final Set<String> wrongIds = {};

  int get total => objects.where((o) => o.kind == SceneObjectKind.hazard).length;

  @override
  MarkerState stateOf(SceneObject o) =>
      found.contains(o.id) ? MarkerState.correct : (wrongIds.contains(o.id) ? MarkerState.wrong : MarkerState.idle);

  @override
  void select(SceneObject o) {
    if (finished || found.contains(o.id) || wrongIds.contains(o.id)) return;
    if (o.kind == SceneObjectKind.hazard) {
      found.add(o.id);
      showInfo(o.info, good: true);
      if (found.length == total) finish(_score());
    } else if (o.kind == SceneObjectKind.safe) {
      wrongIds.add(o.id);
      showInfo(o.info, good: false);
    }
    notifyListeners();
  }

  double _score() => total == 0 ? 0 : (found.length - 0.25 * wrongIds.length) / total;

  @override
  void onTimeUp() => finish(_score(), TaskOutcome.timeUp);
}
