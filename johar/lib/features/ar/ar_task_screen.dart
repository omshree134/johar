import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../core/app_scope.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/services/ar_capability_service.dart';
import '../../core/services/permissions_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/narration_button.dart';
import '../../data/models/localized.dart';
import '../../data/models/module_content.dart';
import 'ar_camera_view.dart';
import 'engine/orientation_source.dart';
import 'engine/projector.dart';
import 'engine/vec3.dart';
import 'render/world_painter.dart';
import 'tasks/choose_exit_task.dart';
import 'tasks/extinguish_task.dart';
import 'tasks/find_hazards_task.dart';
import 'tasks/gas_test_task.dart';
import 'tasks/select_set_task.dart';
import 'tasks/sequence_task.dart';
import 'tasks/task_controller.dart';
import 'tasks/task_factory.dart';

/// Runs a module's AR tasks and returns {taskId: score 0..1} via
/// Navigator.pop, or null if the worker leaves early.
///
/// Rendering tiers (see ArMode): motion sensors on almost every phone, touch
/// drag as the fallback. With camera permission the scene is drawn over the
/// live camera; without it, over a virtual room that moves the same way.
class ArTaskScreen extends StatefulWidget {
  const ArTaskScreen({super.key, required this.module});
  final ModuleContent module;

  @override
  State<ArTaskScreen> createState() => _ArTaskScreenState();
}

class _ArTaskScreenState extends State<ArTaskScreen> with SingleTickerProviderStateMixin {
  static const _virtualFovDeg = 60.0;

  final _orientation = OrientationSource();
  final _frame = ArFrame();
  final _repaint = ValueNotifier<int>(0);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;

  TrackingMode? _tracking;
  bool _hasCamera = false;
  bool _cameraLive = false;
  Size? _previewPortrait;
  double _cameraFovLong = 65;

  bool _started = false;
  int _taskIndex = 0;
  TaskController? _task;
  String? _focusedId;
  SceneObject? _inspected; // item card currently open
  final Map<String, double> _scores = {};

  @override
  void initState() {
    super.initState();
    // Screen "up" must match the phone's top edge for the sensor maths.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _prepare();
  }

  Future<void> _prepare() async {
    final cam = await PermissionsService.hasCamera();
    final fov = await ArCapabilityService.backCameraFovDeg();
    final tracking = await _orientation.start();
    if (!mounted) return;
    setState(() {
      _hasCamera = cam;
      _tracking = tracking;
      if (fov != null) _cameraFovLong = fov;
    });
  }

  @override
  void dispose() {
    Narrator.instance.stop();
    ArCapabilityService.stopEmergencySound();
    _ticker.dispose();
    _orientation.dispose();
    _task?.dispose();
    _repaint.dispose();
    _frame.sprites.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // ---------------- Flow ----------------

  void _begin() {
    _frame.sprites.preload(widget.module.arTasks.expand((t) => t.imageNames));
    _orientation.recenter();
    ArCapabilityService.recordUsed(_tracking == TrackingMode.touch ? ArMode.touch : ArMode.orientation);
    setState(() => _started = true);
    _loadTask(0);
    if (!_ticker.isActive) _ticker.start();
  }

  void _loadTask(int index) {
    final old = _task;
    final next = createTaskController(widget.module.arTasks[index]);
    _frame.task = next;
    setState(() {
      _taskIndex = index;
      _task = next;
      _focusedId = null;
      _inspected = null;
    });
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());

    // Auto-play audio prompt when starting an AR task
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lang = AppScope.of(context).localeController.contentLang;
      Narrator.instance.speak(tr(next.task.prompt, lang), lang);

      // Play ambient emergency cue (fire evacuation siren, gas leak hiss, machinery hum)
      final taskId = next.task.id;
      final modId = widget.module.id;
      if (taskId.contains('escape') || taskId.contains('evacuate') || taskId.contains('fire')) {
        ArCapabilityService.playEmergencySound('siren', volume: 0.28);
      } else if (modId == 'gas' || taskId.contains('gas')) {
        ArCapabilityService.playEmergencySound('gas_hiss', volume: 0.22);
      } else if (modId == 'machinery' || taskId.contains('machine')) {
        ArCapabilityService.playEmergencySound('machinery_hum', volume: 0.25);
      } else {
        ArCapabilityService.stopEmergencySound();
      }
    });
  }

  void _next() {
    Narrator.instance.stop();
    ArCapabilityService.stopEmergencySound();
    final task = _task!;
    _scores[task.task.id] = task.score;
    if (_taskIndex == widget.module.arTasks.length - 1) {
      Navigator.pop(context, Map<String, double>.from(_scores));
    } else {
      _orientation.recenter();
      _loadTask(_taskIndex + 1);
    }
  }

  // ---------------- Per-frame update ----------------

  double _verticalFov(Size screen) {
    if (!_cameraLive) return _virtualFovDeg;
    final p = _previewPortrait;
    final previewAspect = p == null ? 2 / 3 : p.width / p.height;
    final screenAspect = screen.width / screen.height;
    // Preview is cover-fitted: if the screen is wider than the preview, the
    // top and bottom are cropped and the visible vertical angle shrinks.
    if (screenAspect <= previewAspect) return _cameraFovLong;
    final half = math.atan(math.tan(degToRad(_cameraFovLong) / 2) * previewAspect / screenAspect);
    return radToDeg(2 * half);
  }

  void _onTick(Duration now) {
    final dt = _lastTick == Duration.zero ? 1 / 60 : ((now - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _lastTick = now;
    final task = _task;
    final size = _frame.size;
    if (task == null || size.isEmpty) return;

    final pose = _orientation.update(dt);
    final pj = Projector(pose, size, _verticalFov(size));
    final layout = projectScene(pj, task);
    final reticle = size.center(Offset.zero);

    ProjectedObject? focused;
    var best = double.infinity;
    for (final p in layout) {
      if (!p.inFront || !task.isFocusable(p.object) || !p.hitRect.contains(reticle)) continue;
      final d = (p.hitRect.center - reticle).distanceSquared;
      if (d < best) {
        best = d;
        focused = p;
      }
    }

    task.update(
      dt,
      FrameInfo(
        objects: {for (final p in layout) p.object.id: p},
        reticle: reticle,
        size: size,
        focused: focused?.object,
      ),
    );

    _frame.projector = pj;
    _frame.layout = layout;
    _frame.focusedId = focused?.object.id;
    _frame.drawRoom = !_cameraLive;
    _frame.time += dt;
    if (_focusedId != focused?.object.id) setState(() => _focusedId = focused?.object.id);
    _repaint.value++;
  }

  void _onTapUp(TapUpDetails d) {
    final task = _task;
    if (task == null || task.finished) return;
    for (final p in _frame.layout.reversed) {
      // nearest first
      if (p.inFront && task.isSelectable(p.object) && p.hitRect.contains(d.localPosition)) {
        _inspect(p.object);
        return;
      }
    }
  }

  void _inspect(SceneObject o) {
    HapticFeedback.selectionClick();
    _frame.revealed.add(o.id);
    setState(() => _inspected = o);

    // Speak the tapped item name aloud automatically
    final lang = AppScope.of(context).localeController.contentLang;
    final name = tr(o.label, lang);
    Narrator.instance.speak(name, lang);
  }

  void _closeInspect() {
    Narrator.instance.stop();
    setState(() => _inspected = null);
  }

  SceneObject? get _focusedObject {
    for (final p in _frame.layout) {
      if (p.object.id == _focusedId) return p.object;
    }
    return null;
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    if (widget.module.arTasks.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context, <String, double>{}));
      return const SizedBox.shrink();
    }
    return _started ? _buildRunning(context) : _buildIntro(context);
  }

  Widget _buildIntro(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final ready = _tracking != null;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.view_in_ar, size: 56, color: AppColors.manganese),
              const SizedBox(height: 20),
              Text(l.arIntroTitle, style: t.headlineSmall),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber, color: AppColors.coal),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.arIntroStand, style: t.bodyLarge)),
                ]),
              ),
              const SizedBox(height: 16),
              if (ready)
                _IntroLine(
                  icon: _tracking == TrackingMode.touch ? Icons.swipe : Icons.screen_rotation_alt,
                  text: _tracking == TrackingMode.touch ? l.arTrackingTouch : l.arTrackingSensor,
                ),
              _IntroLine(
                icon: _hasCamera ? Icons.photo_camera : Icons.no_photography_outlined,
                text: _hasCamera ? l.arModeCamera : l.cameraPermissionNeeded,
              ),
              const Spacer(),
              if (!_hasCamera) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await PermissionsService.requestCamera();
                    if (mounted) setState(() => _hasCamera = ok);
                  },
                  icon: const Icon(Icons.photo_camera),
                  label: Text(l.allowCamera),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: ready ? _begin : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(l.arStart),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunning(BuildContext context) {
    final task = _task!;
    final touch = _tracking == TrackingMode.touch;
    _frame.lang = AppScope.of(context).localeController.contentLang;

    return Scaffold(
      backgroundColor: const Color(0xFF1F2327),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _frame.size = constraints.biggest;
          return Stack(
            children: [
              if (_hasCamera)
                Positioned.fill(
                  child: ArCameraView(
                    onLiveChanged: (live, preview) {
                      if (!mounted) return;
                      setState(() {
                        _cameraLive = live;
                        _previewPortrait = preview;
                      });
                    },
                  ),
                ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _onTapUp,
                  onPanUpdate: touch ? (d) => _orientation.drag(d.delta, _frame.projector?.focal ?? 600) : null,
                  child: CustomPaint(painter: WorldPainter(_frame, repaint: _repaint)),
                ),
              ),
              ListenableBuilder(
                listenable: task,
                builder: (context, _) => _Hud(
                  task: task,
                  index: _taskIndex,
                  total: widget.module.arTasks.length,
                  touch: touch,
                  focused: _focusedObject,
                  inspected: _inspected,
                  onInspect: _inspect,
                  onCloseInspect: _closeInspect,
                  onClose: () => Navigator.pop(context),
                  onRecenter: _orientation.recenter,
                  onNext: _next,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntroLine extends StatelessWidget {
  const _IntroLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, color: AppColors.slate),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ]),
      );
}

// =====================================================================
// HUD
// =====================================================================

class _Hud extends StatelessWidget {
  const _Hud({
    required this.task,
    required this.index,
    required this.total,
    required this.touch,
    required this.focused,
    required this.inspected,
    required this.onInspect,
    required this.onCloseInspect,
    required this.onClose,
    required this.onRecenter,
    required this.onNext,
  });

  final TaskController task;
  final int index;
  final int total;
  final bool touch;
  final SceneObject? focused;
  final SceneObject? inspected;
  final ValueChanged<SceneObject> onInspect;
  final VoidCallback onCloseInspect;
  final VoidCallback onClose;
  final VoidCallback onRecenter;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = AppScope.of(context).localeController.contentLang;
    final info = task.info;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _PromptCard(
              prompt: tr(task.task.prompt, lang),
              progress: '${index + 1}/$total',
              timeLabel: l.timeLeft(task.secondsLeft),
              fraction: task.timeFraction,
              onClose: onClose,
              onRecenter: touch ? null : onRecenter,
              recenterTooltip: l.arRecenter,
              narration: NarrationButton(text: tr(task.task.prompt, lang), lang: lang, compact: true),
            ),
            if (info != null) ...[
              const SizedBox(height: 8),
              _InfoCard(info: info, lang: lang),
            ],
            const Spacer(),
            if (!task.finished && task.elapsed < 6)
              _Chip(icon: touch ? Icons.swipe : Icons.screen_rotation_alt, text: touch ? l.arTrackingTouch : l.arTrackingSensor),
            const SizedBox(height: 8),
            if (inspected != null && !task.finished)
              _InspectCard(object: inspected!, task: task, lang: lang, onClose: onCloseInspect)
            else if (task.finished)
              _FeedbackPanel(
                title: _outcomeTitle(l),
                good: task.score >= 0.75,
                body: tr(task.task.feedback, lang),
                buttonLabel: index == total - 1 ? l.startQuiz : l.nextTask,
                onNext: onNext,
              )
            else
              _controls(context, l, lang),
          ],
        ),
      ),
    );
  }

  String? _outcomeTitle(AppLocalizations l) => switch (task.outcome) {
        TaskOutcome.timeUp => l.taskTimeUp,
        TaskOutcome.extinguisherEmpty => l.arExtinguisherEmpty,
        TaskOutcome.fireTooBig => l.arFireTooBig,
        _ when task is ExtinguishTask => l.arFireOut,
        _ => task.score >= 0.75 ? l.taskCorrect : null,
      };

  Widget _controls(BuildContext context, AppLocalizations l, String lang) {
    final t = task;
    final canSelect = focused != null && t.isSelectable(focused!);
    final selectButton = FilledButton.icon(
      onPressed: canSelect ? () => onInspect(focused!) : null,
      icon: const Icon(Icons.touch_app),
      label: Text(l.arLookCloser),
    );

    if (t is ExtinguishTask) return _ExtinguishControls(task: t);
    if (t is GasTestTask) return _GasControls(task: t, lang: lang);
    if (t is FindHazardsTask) {
      return Column(children: [
        _Chip(icon: Icons.search, text: l.arFound(t.found.length, t.total)),
        const SizedBox(height: 8),
        selectButton,
      ]);
    }
    if (t is SelectSetTask) {
      return Row(children: [
        Expanded(child: selectButton),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: t.selected.isEmpty ? null : t.check,
            child: Text(l.checkSelection),
          ),
        ),
      ]);
    }
    if (t is ChooseExitTask) return selectButton;
    if (t is SequenceTask) {
      return Column(children: [
        _Chip(icon: Icons.format_list_numbered, text: l.arStepOf(t.done.length + 1 > t.totalSteps ? t.totalSteps : t.done.length + 1, t.totalSteps)),
        const SizedBox(height: 8),
        selectButton,
      ]);
    }
    return const SizedBox.shrink();
  }
}

class _ExtinguishControls extends StatelessWidget {
  const _ExtinguishControls({required this.task});
  final ExtinguishTask task;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        _Gauge(icon: Icons.local_fire_department, label: l.arFireLabel, value: task.intensity, color: AppColors.fireRed),
        const SizedBox(height: 6),
        _Gauge(
          icon: Icons.fire_extinguisher,
          label: l.arExtinguisherLabel,
          value: task.capacityFraction,
          color: AppColors.mandatoryBlue,
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: task.pinPulled ? AppColors.safeGreen : AppColors.manganese,
                disabledBackgroundColor: AppColors.safeGreen,
                disabledForegroundColor: Colors.white,
              ),
              onPressed: task.pinPulled ? null : task.pullPin,
              icon: Icon(task.pinPulled ? Icons.check : Icons.push_pin_outlined),
              label: Text(l.arPullPin),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _HoldButton(
              label: l.arHoldToSpray,
              icon: Icons.fire_extinguisher,
              active: task.spraying,
              onChanged: task.setSpraying,
            ),
          ),
        ]),
      ],
    );
  }
}

class _GasControls extends StatelessWidget {
  const _GasControls({required this.task, required this.lang});
  final GasTestTask task;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reading = task.shownReading;
    final level = task.levelById(task.lastLevelId);
    final lim = task.limits;

    Widget cell(String name, String value, bool ok) => Expanded(
          child: Column(children: [
            Text(name, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: ok ? const Color(0xFF3DDC84) : const Color(0xFFFF6B6B),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        );

    return Column(children: [
      // Detector screen
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF15181B), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.sensors, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                level == null ? l.arPointAtLevel : l.arDetectorTitle(tr(level.label, lang)),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            Text('${task.measured.length}/${task.levels.length}', style: const TextStyle(color: Colors.white70)),
          ]),
          if (reading != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              cell('O2 %', reading.o2.toStringAsFixed(1), lim.o2Ok(reading.o2)),
              cell('H2S ppm', reading.h2s.toStringAsFixed(0), lim.h2sOk(reading.h2s)),
              cell('CO ppm', reading.co.toStringAsFixed(0), lim.coOk(reading.co)),
              cell('LEL %', reading.lel.toStringAsFixed(0), lim.lelOk(reading.lel)),
            ]),
          ],
        ]),
      ),
      const SizedBox(height: 10),
      _HoldButton(
        label: l.arHoldToMeasure,
        icon: Icons.sensors,
        active: task.measuringId != null,
        onChanged: task.setMeasuring,
      ),
      if (task.measured.isNotEmpty) ...[
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.safeGreen),
              onPressed: () => task.decide(safe: true),
              child: Text(l.arDecideSafe, textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.fireRed),
              onPressed: () => task.decide(safe: false),
              child: Text(l.arDecideUnsafe, textAlign: TextAlign.center),
            ),
          ),
        ]),
      ],
    ]);
  }
}

/// Press-and-hold button (spray, measure). Uses raw pointer events so holding
/// works reliably while the worker is also moving the phone.
class _HoldButton extends StatefulWidget {
  const _HoldButton({required this.label, required this.icon, required this.active, required this.onChanged});
  final String label;
  final IconData icon;
  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    if (v) HapticFeedback.lightImpact();
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final on = _down || widget.active;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 58,
        decoration: BoxDecoration(
          color: on ? AppColors.mandatoryBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.mandatoryBlue, width: 2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(widget.icon, color: on ? Colors.white : AppColors.mandatoryBlue),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: on ? Colors.white : AppColors.mandatoryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          SizedBox(width: 96, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0).toDouble(),
                minHeight: 10,
                backgroundColor: AppColors.line,
                color: color,
              ),
            ),
          ),
        ]),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15))),
        ]),
      );
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.progress,
    required this.timeLabel,
    required this.fraction,
    required this.onClose,
    required this.onRecenter,
    required this.recenterTooltip,
    this.narration,
  });
  final Widget? narration;
  final String prompt;
  final String progress;
  final String timeLabel;
  final double fraction;
  final VoidCallback onClose;
  final VoidCallback? onRecenter;
  final String recenterTooltip;

  @override
  Widget build(BuildContext context) {
    final urgent = fraction < 0.3;
    final timeColor = urgent ? AppColors.fireRed : AppColors.slate;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(progress, style: const TextStyle(color: AppColors.slate, fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(Icons.timer_outlined, size: 18, color: timeColor),
              const SizedBox(width: 4),
              Text(timeLabel, style: TextStyle(color: timeColor, fontWeight: FontWeight.w700)),
              if (narration != null) narration!,
              if (onRecenter != null)
                IconButton(tooltip: recenterTooltip, onPressed: onRecenter, icon: const Icon(Icons.center_focus_strong)),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ]),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(prompt, style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: AppColors.line,
                  color: urgent ? AppColors.fireRed : AppColors.manganese,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.info, required this.lang});
  final InfoMessage info;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = info.text != null
        ? tr(info.text!, lang)
        : switch (info.hint!) {
            HudHint.pullPinFirst => l.arPullPinFirst,
            HudHint.aimLower => l.arAimLow,
            HudHint.sweep => l.arSweep,
            HudHint.wrongChoice => l.taskWrong,
            HudHint.wrongOrder => l.arWrongOrder,
          };
    final bg = info.good ? AppColors.safeGreenSoft : (info.hint != null ? AppColors.warningSoft : AppColors.fireRedSoft);
    final icon = info.good ? Icons.check_circle : (info.hint != null ? Icons.lightbulb_outline : Icons.cancel);
    final iconColor = info.good ? AppColors.safeGreen : (info.hint != null ? AppColors.coal : AppColors.fireRed);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ]),
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.title,
    required this.good,
    required this.body,
    required this.buttonLabel,
    required this.onNext,
  });
  final String? title;
  final bool good;
  final String body;
  final String buttonLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(good ? Icons.check_circle : Icons.info, color: good ? AppColors.safeGreen : AppColors.warningYellow, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (title != null) Text(title!, style: t.titleMedium),
                  Text(body, style: t.bodyLarge),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            FilledButton(onPressed: onNext, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}


/// Opens when the worker taps a picture: shows it large with its name, and
/// the action for this task (report, select/remove, go this way, do next).
class _InspectCard extends StatelessWidget {
  const _InspectCard({required this.object, required this.task, required this.lang, required this.onClose});
  final SceneObject object;
  final TaskController task;
  final String lang;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final state = task.stateOf(object);
    final resolved = switch (task) {
      FindHazardsTask() || ChooseExitTask() => state != MarkerState.idle,
      SequenceTask() => state == MarkerState.correct,
      _ => false,
    };

    final (String? label, IconData icon, Color color) = switch (task) {
      FindHazardsTask() => (l.arReportHazard, Icons.report_gmailerrorred, AppColors.fireRed),
      ChooseExitTask() => (l.arGoThisWay, Icons.directions_run, AppColors.safeGreen),
      SelectSetTask(:final selected) => selected.contains(object.id)
          ? (l.arRemove, Icons.remove_circle_outline, AppColors.slate)
          : (l.arSelect, Icons.add_circle_outline, AppColors.manganese),
      SequenceTask() => (l.arDoNext, Icons.play_circle_outline, AppColors.manganese),
      _ => (null, Icons.check, AppColors.manganese),
    };

    final name = tr(object.label, lang);
    final desc = tr(object.description, lang);

    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(color: AppColors.mineral, borderRadius: BorderRadius.circular(22)),
                padding: const EdgeInsets.all(8),
                child: object.imageAsset != null
                    ? Image.asset(object.imageAsset!, fit: BoxFit.contain, filterQuality: FilterQuality.medium)
                    : Icon(Icons.help_outline, size: 56, color: AppColors.slate),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(name, style: t.titleLarge)),
                    NarrationButton(text: desc.isEmpty ? name : '$name. $desc', lang: lang, compact: true),
                  ]),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(desc, style: t.bodyMedium?.copyWith(color: AppColors.slate)),
                  ],
                  if (state == MarkerState.selected || state == MarkerState.correct) ...[
                    const SizedBox(height: 8),
                    _StatusPill(text: l.arSelectedPill, color: AppColors.safeGreen),
                  ],
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton(onPressed: onClose, child: Text(l.arClose)),
              ),
              if (label != null && !resolved) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: color),
                    onPressed: () {
                      task.select(object);
                      onClose();
                    },
                    icon: Icon(icon),
                    label: Text(label, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ]),
      );
}
