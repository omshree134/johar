import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'vec3.dart';

enum TrackingMode {
  /// Gyroscope-based (game rotation vector). Smooth, no compass drift.
  gyro,

  /// Uses the compass. Works without a gyroscope but is shakier near steel.
  compass,

  /// No usable sensors: the worker drags the screen to look around.
  touch,
}

/// Turns the phone's motion sensors into a camera [Pose], relative to the
/// direction the worker faced when the practice started (bearing 0).
class OrientationSource {
  static const _events = EventChannel('johar/orientation');
  static const _method = MethodChannel('johar/ar');

  TrackingMode mode = TrackingMode.touch;
  StreamSubscription<dynamic>? _sub;

  Vec3? _rawF, _rawU;
  Pose _smooth = Pose.initial;
  double _yaw0 = 0; // world bearing that counts as "straight ahead"
  bool _needsRecenter = true;

  double _touchYaw = 0, _touchPitch = 0;

  Future<TrackingMode> start() async {
    String? source;
    try {
      source = await _method.invokeMethod<String>('orientationSource');
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
    if (source == null || source == 'none') return mode = TrackingMode.touch;

    mode = source == 'gameRotationVector' ? TrackingMode.gyro : TrackingMode.compass;
    _sub = _events.receiveBroadcastStream().listen(
      (e) {
        final v = (e as List).cast<double>();
        _rawF = Vec3(v[0], v[1], v[2]);
        _rawU = Vec3(v[3], v[4], v[5]);
      },
      onError: (_) => mode = TrackingMode.touch,
    );

    // Some phones list a sensor that never reports. Fall back if silent.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (_rawF == null) {
      await _sub?.cancel();
      _sub = null;
      mode = TrackingMode.touch;
    }
    return mode;
  }

  /// Makes the current facing direction bearing 0.
  void recenter() {
    _needsRecenter = true;
    _touchYaw = 0;
    _touchPitch = 0;
  }

  /// Touch mode: dragging right turns the view left, like moving a photo.
  void drag(Offset delta, double focalPx) {
    if (mode != TrackingMode.touch || focalPx <= 0) return;
    _touchYaw -= radToDeg(delta.dx / focalPx);
    _touchPitch = (_touchPitch + radToDeg(delta.dy / focalPx)).clamp(-80.0, 80.0).toDouble();
  }

  /// Call once per frame. Returns the smoothed pose in scene coordinates.
  Pose update(double dt) {
    if (mode == TrackingMode.touch) return Pose.fromYawPitch(_touchYaw, _touchPitch);
    final f = _rawF, u = _rawU;
    if (f == null || u == null) return Pose.initial;

    final raw = Pose(f, u).orthonormalized();
    // Low-pass filter: gyro data is already clean, compass data needs more.
    final tau = mode == TrackingMode.gyro ? 0.05 : 0.18;
    final k = 1 - math.exp(-dt / tau);
    _smooth = Pose(Vec3.lerp(_smooth.forward, raw.forward, k), Vec3.lerp(_smooth.up, raw.up, k)).orthonormalized();

    if (_needsRecenter) {
      _smooth = raw;
      _yaw0 = raw.forward.bearingDeg;
      _needsRecenter = false;
    }
    return _smooth.shiftBearing(-_yaw0);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
