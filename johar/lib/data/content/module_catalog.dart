import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/widgets/sign_badge.dart';
import '../models/module_content.dart';

/// The five industrial safety domains. All five modules are complete and available offline.
class ModuleCatalogEntry {
  const ModuleCatalogEntry({required this.id, required this.sign, required this.icon, required this.title, this.asset});
  final String id;
  final SignKind sign;
  final String icon;
  final String Function(AppLocalizations) title;
  final String? asset;
  bool get available => asset != null;
}

final List<ModuleCatalogEntry> moduleCatalog = [
  ModuleCatalogEntry(id: 'fire', sign: SignKind.fireEquipment, icon: 'fire', title: (l) => l.moduleFire, asset: 'assets/modules/fire.json'),
  ModuleCatalogEntry(id: 'gas', sign: SignKind.warning, icon: 'gas', title: (l) => l.moduleGas, asset: 'assets/modules/gas.json'),
  ModuleCatalogEntry(id: 'machinery', sign: SignKind.prohibition, icon: 'machinery', title: (l) => l.moduleMachinery, asset: 'assets/modules/machinery.json'),
  ModuleCatalogEntry(id: 'electrical', sign: SignKind.mandatory, icon: 'electric', title: (l) => l.moduleElectrical, asset: 'assets/modules/electrical.json'),
  ModuleCatalogEntry(id: 'firstaid', sign: SignKind.safeCondition, icon: 'firstaid', title: (l) => l.moduleFirstAid, asset: 'assets/modules/first_aid.json'),
];

class ContentRepository {
  final Map<String, ModuleContent> _cache = {};

  /// Content ships inside the APK, so training works with zero connectivity.
  Future<ModuleContent> load(ModuleCatalogEntry entry) async {
    final cached = _cache[entry.id];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(entry.asset!);
    return _cache[entry.id] = ModuleContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
