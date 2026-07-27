import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';

/// A "liquid glass" surface: a blurred, translucent panel with a soft gradient
/// sheen. Adapts to the current [Brightness].
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final tint = isDark ? Colors.white : context.colors.accent;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: isDark ? 0.16 : 0.12),
                  tint.withValues(alpha: isDark ? 0.06 : 0.04),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
