import 'package:flutter/material.dart';
import '../models/sales_model.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';

class OutletSelectorModal extends StatelessWidget {
  final List<OutletInfo> outlets;
  final OutletInfo selectedOutlet;
  final ValueChanged<OutletInfo> onSelected;

  const OutletSelectorModal({
    super.key,
    required this.outlets,
    required this.selectedOutlet,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required List<OutletInfo> outlets,
    required OutletInfo selectedOutlet,
    required ValueChanged<OutletInfo> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => OutletSelectorModal(
        outlets: outlets,
        selectedOutlet: selectedOutlet,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    AppLogo(size: 28, borderRadius: 7),
                    SizedBox(width: 10),
                    Text(
                      'Select Outlet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.iceBlue),
                  ),
                  child: const Text(
                    'Online Sync Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Switch between your store branches to view real-time metrics',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...outlets.map((outlet) {
              final isSelected = outlet.id == selectedOutlet.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlueLight : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: AppLogo(
                    size: 38,
                    borderRadius: 9,
                    showBorder: true,
                    borderColor: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.cardBorder,
                  ),
                  title: Text(
                    outlet.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${outlet.location} • POS ID: ${outlet.posTerminalId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryBlue,
                        )
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                  onTap: () {
                    onSelected(outlet);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
