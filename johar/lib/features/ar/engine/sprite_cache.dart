import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// Decodes item pictures once into GPU images the painter can draw every
/// frame. Images are decoded at 256 px, which is plenty on phone screens and
/// keeps memory low on budget devices.
class SpriteCache {
  final Map<String, ui.Image> _images = {};
  final Set<String> _loading = {};

  ui.Image? operator [](String? name) => name == null ? null : _images[name];

  Future<void> preload(Iterable<String> names) => Future.wait(names.toSet().map(_load));

  Future<void> _load(String name) async {
    if (_images.containsKey(name) || !_loading.add(name)) return;
    try {
      final data = await rootBundle.load('assets/ar/items/$name.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 256);
      _images[name] = (await codec.getNextFrame()).image;
    } catch (_) {
      // Missing picture: the painter falls back to the icon.
    } finally {
      _loading.remove(name);
    }
  }

  void dispose() {
    for (final img in _images.values) {
      img.dispose();
    }
    _images.clear();
  }
}
