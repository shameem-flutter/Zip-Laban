import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ResponsiveFrame extends StatelessWidget {
  final Widget child;

  const ResponsiveFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On mobile and tablet screens (up to 768px), render 100% full screen
        if (constraints.maxWidth <= 768) {
          return child;
        }

        // On wide desktop monitors, center the app comfortably with clean framing
        return Material(
          color: AppColors.background,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
