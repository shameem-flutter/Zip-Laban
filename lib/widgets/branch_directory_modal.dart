import 'package:flutter/material.dart';
import '../models/odoo_company.dart';
import '../services/company_service.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';

class BranchDirectoryModal extends StatefulWidget {
  const BranchDirectoryModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const BranchDirectoryModal(),
    );
  }

  @override
  State<BranchDirectoryModal> createState() => _BranchDirectoryModalState();
}

class _BranchDirectoryModalState extends State<BranchDirectoryModal> {
  final CompanyService _companyService = CompanyService();

  @override
  void initState() {
    super.initState();
    _companyService.fetchCompanies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _companyService,
        builder: (context, _) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
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
                    Expanded(
                      child: Row(
                        children: [
                          const AppLogo(size: 28, borderRadius: 7),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Branches & Companies',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Connected Outlets & Locations',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryBlue.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh Company Data',
                      icon: _companyService.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBlue,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, color: AppColors.primaryBlue),
                      onPressed: _companyService.isLoading
                          ? null
                          : () => _companyService.fetchCompanies(forceRefresh: true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.iceBlue),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _companyService.isFromLiveApi
                            ? Icons.cloud_done_rounded
                            : Icons.info_outline_rounded,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _companyService.isFromLiveApi
                              ? 'Live sync active from ziplaban.odoo.waslasoft.com'
                              : 'Cached branch configuration active',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlueDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_companyService.companies.length} branches',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_companyService.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      _companyService.errorMessage!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _companyService.companies.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final company = _companyService.companies[index];
                      return _buildBranchCard(company);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBranchCard(OdooCompany company) {
    final outlet = company.toOutletInfo();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const AppLogo(
            size: 44,
            borderRadius: 10,
            showBorder: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        company.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.iceBlueSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ID: ${company.id}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${outlet.location} • POS ID: ${outlet.posTerminalId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
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
                fontWeight: FontWeight.w700,
                color: AppColors.greenIcon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
