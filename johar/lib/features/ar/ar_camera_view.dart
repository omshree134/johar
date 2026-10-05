// Live back-camera feed for AR. Adapted from Safar's live_survey_screen.dart
// camera setup, with lifecycle handling. Replaces camera_backdrop.dart.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/services/permissions_service.dart';

/// [onLiveChanged] reports whether the feed is showing, plus the preview size
/// in portrait (width < height) so the AR layer can match the camera's view.
class ArCameraView extends StatefulWidget {
  const ArCameraView({super.key, required this.onLiveChanged});
  final void Function(bool live, Size? portraitPreview) onLiveChanged;

  @override
  State<ArCameraView> createState() => _ArCameraViewState();
}

class _ArCameraViewState extends State<ArCameraView> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    if (_starting || _controller != null) return;
    _starting = true;
    try {
      if (!await PermissionsService.hasCamera()) throw CameraException('permission', 'denied');
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('none', 'No camera');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      // Medium resolution keeps GPU and battery load low on budget phones.
      final controller = CameraController(back, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      final s = controller.value.previewSize;
      widget.onLiveChanged(true, s == null ? null : Size(s.shortestSide, s.longestSide));
    } catch (_) {
      if (mounted) widget.onLiveChanged(false, null);
    } finally {
      _starting = false;
    }
  }

  Future<void> _release() async {
    final c = _controller;
    if (c == null) return;
    setState(() => _controller = null);
    widget.onLiveChanged(false, null);
    await c.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _release();
    } else if (state == AppLifecycleState.resumed) {
      _start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.expand();
    final size = c.value.previewSize!;
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(width: size.shortestSide, height: size.longestSide, child: CameraPreview(c)),
        ),
      ),
    );
  }
}
