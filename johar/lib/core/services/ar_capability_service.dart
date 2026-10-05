import 'package:flutter/services.dart';

/// The three AR tiers, best first. The same scene files run on all of them.
enum ArMode {
  /// ARCore 6-DoF: objects anchored to real floors and walls. (Phase 2.)
  worldTracking,

  /// Motion sensors (3-DoF): objects stay fixed in the room as the worker
  /// turns. Works on nearly every Android 10+ phone. This is the default.
  orientation,

  /// No usable sensors: drag the screen to look around.
  touch,
}

/// Flip to true once the ARCore renderer exists.
const bool kWorldArImplemented = false;

class ArCapabilityService {
  ArCapabilityService._();

  static const _channel = MethodChannel('johar/ar');
  static ArMode _lastUsed = ArMode.touch;
  static String? arCoreStatus;

  /// True if ARCore is installed and supported (for the phase-2 tier).
  static Future<bool> arCoreReady() async {
    try {
      for (var i = 0; i < 10; i++) {
        final status = await _channel.invokeMethod<String>('checkArCore');
        arCoreStatus = status;
        if (status != 'UNKNOWN_CHECKING') return status == 'SUPPORTED_INSTALLED';
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
    return false;
  }

  /// Field of view across the long side of the back camera, from the lens
  /// and sensor specs. Null if unknown; callers use a typical 65 degrees.
  static Future<double?> backCameraFovDeg() async {
    try {
      final v = await _channel.invokeMethod<double>('backCameraFov');
      if (v != null && v > 40 && v < 100) return v;
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
    return null;
  }

  static void recordUsed(ArMode mode) => _lastUsed = mode;

  /// The tier used in the latest practice session (stored with each attempt).
  static Future<ArMode> effectiveMode() async => _lastUsed;

  /// Plays ambient emergency sound effects (siren, gas_hiss, machinery_hum).
  static Future<void> playEmergencySound(String sound, {double volume = 0.3}) async {
    try {
      await _channel.invokeMethod<void>('playEmergencySound', {'sound': sound, 'volume': volume});
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
  }

  /// Stops current ambient emergency sound.
  static Future<void> stopEmergencySound() async {
    try {
      await _channel.invokeMethod<void>('stopEmergencySound');
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
  }
}
