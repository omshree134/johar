import 'package:flutter/material.dart';
import 'core/app_scope.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/l10n/santali_fallback_delegates.dart';
import 'core/services/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'data/content/module_catalog.dart';
import 'data/local/local_store.dart';
import 'data/sync/sync_service.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/language_screen.dart';
import 'features/onboarding/splash_screen.dart';

class JoharApp extends StatelessWidget {
  const JoharApp({
    super.key,
    required this.store,
    required this.sync,
    required this.localeController,
    required this.content,
  });

  final LocalStore store;
  final SyncService sync;
  final LocaleController localeController;
  final ContentRepository content;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      sync: sync,
      localeController: localeController,
      content: content,
      child: ListenableBuilder(
        listenable: localeController,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
          theme: AppTheme.light(),
          locale: localeController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            ...santaliFallbackDelegates, // must come first
            ...AppLocalizations.localizationsDelegates,
          ],
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

/// Root gate after splash: language/registration -> training home.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.localeController, scope.store]),
      builder: (context, _) {
        if (scope.store.activeWorker == null) return const LanguageScreen();
        return const HomeShell();
      },
    );
  }
}
