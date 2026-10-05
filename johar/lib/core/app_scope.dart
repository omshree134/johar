import 'package:flutter/widgets.dart';
import '../data/content/module_catalog.dart';
import '../data/local/local_store.dart';
import '../data/sync/sync_service.dart';
import 'services/locale_controller.dart';

/// Hands the app-wide services to every screen without a state package.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.store,
    required this.sync,
    required this.localeController,
    required this.content,
    required super.child,
  });

  final LocalStore store;
  final SyncService sync;
  final LocaleController localeController;
  final ContentRepository content;

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
