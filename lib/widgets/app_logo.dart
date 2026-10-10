import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Reusable Waslasoft Restaurant App Logo widget
/// Displays the official Waslasoft dining logo (plate, fork, knife, Arabic & English brandmark)
class AppLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final bool isCircle;
  final bool showShadow;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.size = 40,
    this.borderRadius,
    this.isCircle = false,
    this.showShadow = false,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1.0,
    this.fit = BoxFit.contain,
  });

  const AppLogo.circle({
    super.key,
    this.size = 40,
    this.showShadow = false,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1.0,
    this.fit = BoxFit.contain,
  })  : isCircle = true,
        borderRadius = null;

  const AppLogo.card({
    super.key,
    this.size = 54,
    this.borderRadius = 14,
    this.showShadow = true,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1.2,
    this.fit = BoxFit.contain,
  }) : isCircle = false;

  static const String assetPath = 'assets/images/waslasoft_logo.png';
  static const String webIconPath = 'icons/Icon-512.png';

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = isCircle
        ? BorderRadius.circular(size / 2)
        : BorderRadius.circular(borderRadius ?? (size * 0.22));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        border: showBorder
            ? Border.all(
                color: borderColor ?? const Color(0xFFE2E8F0),
                width: borderWidth,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF0F56D9).withValues(alpha: 0.16),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: _buildImage(context, effectiveRadius),
      ),
    );
  }

  Widget _buildImage(BuildContext context, BorderRadius effectiveRadius) {
    if (kIsWeb) {
      // On Flutter Web, directly load the web icon static file to avoid dev-server bundle 404s
      return Image.network(
        webIconPath,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                _fallback(effectiveRadius),
          );
        },
      );
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          _fallback(effectiveRadius),
    );
  }

  Widget _fallback(BorderRadius effectiveRadius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F56D9), Color(0xFF0038A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: effectiveRadius,
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: size * 0.55,
          color: Colors.white,
        ),
      ),
    );
  }
}
