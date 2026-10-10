import 'package:flutter/material.dart';
import '../models/sales_model.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/salesperson_directory_modal.dart';
import 'customer_directory_view.dart';
import 'product_catalog_view.dart';
import '../services/pwa_install/pwa_install_service.dart';

class MoreView extends StatelessWidget {
  final OutletInfo outlet;

  const MoreView({super.key, required this.outlet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'More & Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Outlet info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const AppLogo.card(size: 50, borderRadius: 12),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outlet.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${outlet.location} • POS ID ${outlet.posTerminalId}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.greenBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greenIcon,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // PWA Install Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const AppLogo(
                  size: 36,
                  borderRadius: 9,
                  showBorder: true,
                  borderColor: Colors.white30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Install as PWA App',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Add to home screen for 1-tap fast analytics tracking',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => PwaInstallService.promptInstall(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryBlue,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Install',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Store Operations & POS Actions Group
          _buildSettingsGroup('Store Operations & Management', [
            _settingTile(
              Icons.inventory_2_outlined,
              'Menu & Products Catalog',
              'Dishes, categories & pricing',
              onTap: () => ProductCatalogView.showModal(context),
            ),
            _settingTile(
              Icons.people_alt_outlined,
              'Customer Directory & Accounts',
              'Customer records & credit ledgers',
              onTap: () => CustomerDirectoryView.showModal(context),
            ),
            _settingTile(
              Icons.people_outline,
              'Staff & Waiters Directory',
              'Active waiters, cashiers & shift teams',
              onTap: () => SalespersonDirectoryModal.show(context),
            ),
          ]),

          const SizedBox(height: 16),

          _buildSettingsGroup('System Information', [
            _settingTile(
              Icons.cloud_done_outlined,
              'Cloud Connection',
              'Online & Synchronized',
            ),
            _settingTile(
              Icons.info_outline,
              'Waslasoft Restaurant Version',
              'v1.0.4 • PWA Analytics Suite',
            ),
          ]),

          const SizedBox(height: 24),

          // Logout Action Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
              title: const Text(
                'Sign Out / Switch Terminal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
              subtitle: const Text(
                'End current session and return to login',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    content: const Text(
                      'Do you want to log out of your current terminal session?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          AuthService().logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Brand Footer
          Center(
            child: Column(
              children: [
                const AppLogo(
                  size: 32,
                  borderRadius: 8,
                  showShadow: true,
                ),
                const SizedBox(height: 8),
                const Text(
                  'WASLASOFT RESTAURANT • وصلة سوفت',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F56D9),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Enterprise Dining & POS Management Suite',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _settingTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
