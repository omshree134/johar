import 'package:flutter/material.dart';

/// Icons referenced by name from module JSON files. Add new ones here.
abstract final class AppIcons {
  static const Map<String, IconData> _byName = {
    'fire': Icons.local_fire_department,
    'alarm': Icons.campaign,
    'exit': Icons.directions_run,
    'extinguisher': Icons.fire_extinguisher,
    'stairs': Icons.stairs,
    'elevator': Icons.elevator,
    'assembly': Icons.groups,
    'smoke': Icons.cloud,
    'gas': Icons.air,
    'detector': Icons.sensors,
    'harness': Icons.link,
    'helmet': Icons.engineering,
    'breathing': Icons.masks,
    'mask': Icons.face,
    'matches': Icons.whatshot,
    'permit': Icons.assignment_turned_in,
    'buddy': Icons.people,
    'wind': Icons.wind_power,
    'pit': Icons.vertical_align_bottom,
    'tank': Icons.propane_tank,
    'water': Icons.water_drop,
    'foam': Icons.bubble_chart,
    'powder': Icons.grain,
    'co2': Icons.co2,
    'machinery': Icons.precision_manufacturing,
    'electric': Icons.electrical_services,
    'firstaid': Icons.medical_services,
    'warning': Icons.warning_amber,
    'check': Icons.check_circle,
  };

  static IconData of(String name) => _byName[name] ?? Icons.help_outline;
}
