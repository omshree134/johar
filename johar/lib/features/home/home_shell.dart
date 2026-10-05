import 'package:flutter/material.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../certificate/certificates_screen.dart';
import '../certificate/verify_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Built on demand so the scanner camera only runs on its tab.
    final body = switch (_index) {
      0 => const HomeScreen(),
      1 => const CertificatesScreen(),
      _ => const VerifyScreen(),
    };
    return Scaffold(
      body: body,
      // Floating rounded navigation bar.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg + 4),
            boxShadow: kCardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg + 4),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.school_outlined),
                  selectedIcon: const Icon(Icons.school_rounded),
                  label: l.navLearn,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.workspace_premium_outlined),
                  selectedIcon: const Icon(Icons.workspace_premium_rounded),
                  label: l.navCertificates,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: l.navVerify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
