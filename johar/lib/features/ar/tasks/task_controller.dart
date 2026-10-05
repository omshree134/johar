import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../../data/models/ar_task.dart';
import '../../../data/models/localized.dart';
import '../engine/projector.dart';

/// What the camera sees this frame, handed to the task logic.
class FrameInfo {
  FrameInfo({required this.objects, required this.reticle, required this.size, this.focused});
  final Map<String, ProjectedObject> objects;
  final Offset reticle; // screen centre, where the worker is aiming
  final Size size;
  final SceneObject? focused; // object under the reticle, if any
}

enum MarkerState { idle, selected, correct, wrong }

enum TaskOutcome { done, timeUp, extinguisherEmpty, fireTooBig }

/// Short coaching messages that come from the app, not the content file.
enum HudHint { pullPinFirst, aimLower, sweep, wrongChoice, wrongOrder }

class InfoMessage {
  InfoMessage({this.text, this.hint, required this.good, required this.until});
  final LocalizedText? text;
  final HudHint? hint;
  final bool good;
  final double until;
}

/// Base class for one AR task. Pure logic: no widgets, so it is unit-tested.
abstract class TaskController extends ChangeNotifier {
  TaskController(this.task);

  final ArTask task;
  double elapsed = 0;
  bool finished = false;
  double score = 0;
  TaskOutcome? outcome;
  InfoMessage? _info;
  int _lastSecond = -1;
  double _lastFastNotify = 0;

  List<SceneObject> get objects => task.objects;
  int get secondsLeft => (task.timeLimitSec - elapsed).ceil().clamp(0, task.timeLimitSec).toInt();
  double get timeFraction => task.timeLimitSec == 0 ? 0 : (1 - elapsed / task.timeLimitSec).clamp(0.0, 1.0).toDouble();
  InfoMessage? get info => (_info != null && elapsed < _info!.until) ? _info : null;

  /// HUD needs ~10 updates a second (gauges), not just once a second.
  bool get wantsFastHud => false;

  bool isSelectable(SceneObject o) => switch (o.kind) {
        SceneObjectKind.hazard || SceneObjectKind.safe || SceneObjectKind.exit || SceneObjectKind.item => true,
        _ => false,
      };

  bool isFocusable(SceneObject o) => isSelectable(o);
  MarkerState stateOf(SceneObject o) => MarkerState.idle;

  /// Objects that get an arrow at the screen edge when out of view.
  Set<String> get guideIds => const {};

  /// Fires in non-extinguish tasks slowly grow for realism.
  double fireIntensity(SceneObject o) => (0.55 + elapsed * 0.01).clamp(0.0, 0.95).toDouble();

  void update(double dt, FrameInfo frame) {
    if (finished) return;
    elapsed += dt;
    tick(dt, frame);
    if (!finished && elapsed >= task.timeLimitSec) onTimeUp();

    final second = elapsed.floor();
    final infoExpired = _info != null && elapsed >= _info!.until;
    if (infoExpired) _info = null;
    if (second != _lastSecond || infoExpired || (wantsFastHud && elapsed - _lastFastNotify >= 0.1)) {
      _lastSecond = second;
      _lastFastNotify = elapsed;
      notifyListeners();
    }
  }

  @protected
  void tick(double dt, FrameInfo frame) {}

  /// Worker tapped an object or pressed Select while aiming at it.
  void select(SceneObject o) {}

  @protected
  void onTimeUp() => finish(0, TaskOutcome.timeUp);

  @protected
  void finish(double s, [TaskOutcome o = TaskOutcome.done]) {
    if (finished) return;
    finished = true;
    score = s.clamp(0.0, 1.0).toDouble();
    outcome = o;
    notifyListeners();
  }

  @protected
  void showInfo(LocalizedText text, {required bool good, double seconds = 3.5}) {
    _info = InfoMessage(text: text, good: good, until: elapsed + seconds);
    notifyListeners();
  }

  @protected
  void showHint(HudHint hint, {double seconds = 2}) {
    if (info != null) return; // don't cover a message the worker is reading
    _info = InfoMessage(hint: hint, good: false, until: elapsed + seconds);
    notifyListeners();
  }
}
