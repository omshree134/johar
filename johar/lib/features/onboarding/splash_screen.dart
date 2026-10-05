import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/sohrai_pattern.dart';
import '../home/home_shell.dart';
import 'language_screen.dart';

/// Animated cold-start entrance splash screen for Johar.
/// Features a smooth entrance animation of the Johar safety emblem,
/// displaying the brand promise before transitioning into language selection or home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto navigate after 1.8 seconds
    _timer = Timer(const Duration(milliseconds: 1900), _proceed);
  }

  void _proceed() {
    if (!mounted) return;
    final scope = AppScope.of(context);
    final isRegistered = scope.store.activeWorker != null;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            isRegistered ? const HomeShell() : const LanguageScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.manganeseDeep,
      body: Stack(
        children: [
          // Background Sohrai art line at the bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SohraiPattern(height: 90, line: Color(0x1FFFFFFF)),
          ),

          // Centered Animated Emblem & Branding
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF4B400).withValues(alpha: 0.35),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.manganese,
                            child: const Icon(Icons.shield_rounded, size: 60, color: AppColors.warningYellow),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'JOHAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'जोहार • ᱡᱚᱦᱟᱨ',
                    style: TextStyle(
                      color: Color(0xFFE7E3F1),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'सुरक्षित काम, सुरक्षित घर',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Loading / Skip indicator
          Positioned(
            left: 0,
            right: 0,
            bottom: 42,
            child: Center(
              child: GestureDetector(
                onTap: _proceed,
                child: const Text(
                  'Tap to skip',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
