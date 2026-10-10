import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'pwa_install_platform_stub.dart'
    if (dart.library.js_interop) 'pwa_install_platform_web.dart';

/// Service managing PWA installation prompts across Web, iOS and Desktop
class PwaInstallService {
  PwaInstallService._();

  /// Prompts the user to install the PWA or shows instructions
  static Future<void> promptInstall(BuildContext context) async {
    final outcome = await PwaInstallPlatform.triggerInstall();

    if (!context.mounted) return;

    if (outcome == 'accepted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Waslasoft Restaurant installed successfully to your device!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (outcome == 'already_installed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F56D9),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Waslasoft Restaurant is already installed on your device.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else if (outcome == 'ios_manual') {
      _showIosGuide(context);
    } else if (outcome == 'browser_prompt_unavailable' ||
        outcome == 'desktop_or_pending' ||
        outcome == 'unsupported_platform') {
      _showDesktopGuide(context);
    }
  }

  static void _showIosGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.apple, color: Colors.black, size: 24),
            SizedBox(width: 8),
            Text(
              'Install on iOS Safari',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To install Waslasoft Restaurant on your iPhone or iPad:',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              '1. Tap the Share button in Safari (at the bottom or top).',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              '2. Scroll down and tap "Add to Home Screen".',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              '3. Tap "Add" in the top right corner.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  static void _showDesktopGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.install_desktop_rounded,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Install Waslasoft App',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'To install this app on your device:',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
            SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.desktop_windows_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Look at your browser address bar (top right). Click the Install icon (computer with down arrow).',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Or open Chrome Menu (⋮) → "Save and share" → "Install Waslasoft Restaurant".',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }
}
