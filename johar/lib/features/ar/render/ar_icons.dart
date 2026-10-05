import 'package:flutter/material.dart';
import '../../../core/widgets/app_icons.dart';

/// Extra icons used by AR scenes; falls back to the app-wide registry.
const Map<String, IconData> _arIcons = {
  'oil': Icons.opacity,
  'socket': Icons.power,
  'smoking': Icons.smoking_rooms,
  'drum': Icons.oil_barrel,
  'cable': Icons.cable,
  'boxes': Icons.inventory_2,
  'bin': Icons.delete,
  'shed': Icons.warehouse,
  'cylinder': Icons.propane_tank,
  'level': Icons.radio_button_unchecked,
  'sign': Icons.signpost,
};

IconData arIcon(String name) => _arIcons[name] ?? AppIcons.of(name);
