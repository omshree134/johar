import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'sohrai_pattern.dart';

/// Deep manganese header with rounded bottom corners and the Sohrai band.
/// Put a floating card under it with [overlap] to create depth.
class JoharHeader extends StatelessWidget {
  const JoharHeader({super.key, required this.child, this.overlap = 0, this.bottomPadding = 28});
  final Widget child;
  final double overlap; // extra space for a card that overlaps the header
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadii.xl)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.manganese, AppColors.manganeseDeep],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(left: 0, right: 0, bottom: 0, child: SohraiPattern(height: 70)),
            Padding(
              padding: EdgeInsets.fromLTRB(20, top + 12, 12, bottomPadding + overlap),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// White rounded card with the soft shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: kCardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Small rounded status pill.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, required this.color, this.icon, this.background});
  final String text;
  final Color color;
  final IconData? icon;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background ?? color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 5)],
          Flexible(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14))),
        ]),
      );
}
