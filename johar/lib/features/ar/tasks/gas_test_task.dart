import 'dart:math' as math;
import '../../../data/models/ar_task.dart';
import '../../../data/models/localized.dart';
import 'task_controller.dart';

class GasReading {
  const GasReading({required this.o2, required this.h2s, required this.co, required this.lel});
  final double o2; // % volume
  final double h2s; // ppm
  final double co; // ppm
  final double lel; // % of lower explosive limit

  factory GasReading.fromJson(Map<String, dynamic> j) => GasReading(
        o2: (j['o2'] as num).toDouble(),
        h2s: (j['h2s'] as num? ?? 0).toDouble(),
        co: (j['co'] as num? ?? 0).toDouble(),
        lel: (j['lel'] as num? ?? 0).toDouble(),
      );
}

/// Alarm levels. Defaults are common 4-gas detector settings; set the values
/// your site's standard uses in the module JSON.
class GasLimits {
  const GasLimits({this.o2Min = 19.5, this.o2Max = 23.5, this.h2sMax = 10, this.coMax = 35, this.lelMax = 10});
  final double o2Min, o2Max, h2sMax, coMax, lelMax;

  factory GasLimits.fromJson(Map<String, dynamic>? j) => j == null
      ? const GasLimits()
      : GasLimits(
          o2Min: (j['o2Min'] as num? ?? 19.5).toDouble(),
          o2Max: (j['o2Max'] as num? ?? 23.5).toDouble(),
          h2sMax: (j['h2sMax'] as num? ?? 10).toDouble(),
          coMax: (j['coMax'] as num? ?? 35).toDouble(),
          lelMax: (j['lelMax'] as num? ?? 10).toDouble(),
        );

  bool o2Ok(double v) => v >= o2Min && v <= o2Max;
  bool h2sOk(double v) => v <= h2sMax;
  bool coOk(double v) => v <= coMax;
  bool lelOk(double v) => v <= lelMax;
  bool allOk(GasReading r) => o2Ok(r.o2) && h2sOk(r.h2s) && coOk(r.co) && lelOk(r.lel);
}

class GasLevel {
  GasLevel({required this.id, required this.label, required this.elevation, required this.reading});
  final String id;
  final LocalizedText label;
  final double elevation;
  final GasReading reading;
}

/// Pre-entry gas test: aim the phone into the sump at the top, middle and
/// bottom (by tilting down), hold Measure at each, then decide.
/// Score = 50% for levels tested + 50% for the correct entry decision.
class GasTestTask extends TaskController {
  GasTestTask(super.task)
      : limits = GasLimits.fromJson(task.config['limits'] as Map<String, dynamic>?),
        holdSec = (task.config['holdSec'] as num? ?? 2).toDouble() {
    final sump = task.objects.firstWhere((o) => o.kind == SceneObjectKind.sump, orElse: () => task.objects.first);
    for (final l in task.config['levels'] as List? ?? const []) {
      final m = l as Map<String, dynamic>;
      final level = GasLevel(
        id: m['id'] as String,
        label: parseLocalized(m['label']),
        elevation: (m['elevation'] as num).toDouble(),
        reading: GasReading.fromJson(m['readings'] as Map<String, dynamic>),
      );
      levels.add(level);
      _levelObjects.add(SceneObject(
        id: level.id,
        kind: SceneObjectKind.level,
        label: level.label,
        icon: 'level',
        bearing: sump.bearing,
        elevation: level.elevation,
        distance: 1.8,
      ));
    }
    _sumpId = sump.id;
  }

  final GasLimits limits;
  final double holdSec;
  final List<GasLevel> levels = [];
  final List<SceneObject> _levelObjects = [];
  late final String _sumpId;

  final Map<String, GasReading> measured = {};
  String? lastLevelId;
  String? measuringId;
  double progress = 0; // 0..1 for the level being measured
  bool _holding = false;
  bool? decidedSafe;

  @override
  List<SceneObject> get objects => [...task.objects, ..._levelObjects];

  @override
  bool get wantsFastHud => true;

  @override
  Set<String> get guideIds => {_sumpId};

  @override
  bool isSelectable(SceneObject o) => false;

  @override
  bool isFocusable(SceneObject o) => o.kind == SceneObjectKind.level;

  @override
  MarkerState stateOf(SceneObject o) => measured.containsKey(o.id) ? MarkerState.correct : MarkerState.idle;

  bool get actuallySafe => levels.every((l) => limits.allOk(l.reading));
  double get coverage => levels.isEmpty ? 0 : measured.length / levels.length;
  GasReading? get shownReading => lastLevelId == null ? null : measured[lastLevelId];
  GasLevel? levelById(String? id) => levels.where((l) => l.id == id).firstOrNull;

  void setMeasuring(bool held) {
    if (finished) return;
    _holding = held;
    if (!held) progress = 0;
    notifyListeners();
  }

  @override
  void tick(double dt, FrameInfo frame) {
    final f = frame.focused;
    if (!_holding || f == null || f.kind != SceneObjectKind.level) {
      progress = math.max(0, progress - dt * 2);
      if (progress == 0) measuringId = null;
      return;
    }
    if (measuringId != f.id) {
      measuringId = f.id;
      progress = 0;
    }
    progress += dt / holdSec;
    if (progress >= 1) {
      measured[f.id] = levelById(f.id)!.reading;
      lastLevelId = f.id;
      progress = 0;
      measuringId = null;
      notifyListeners();
    }
  }

  void decide({required bool safe}) {
    if (finished || measured.isEmpty) return;
    decidedSafe = safe;
    finish(0.5 * coverage + (safe == actuallySafe ? 0.5 : 0));
  }

  @override
  void onTimeUp() => finish(0.5 * coverage * 0.5, TaskOutcome.timeUp);
}
