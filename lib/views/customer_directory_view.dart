import 'package:flutter/material.dart';
import '../models/odoo_customer.dart';
import '../services/customer_service.dart';
import '../theme/app_colors.dart';

class CustomerDirectoryView extends StatefulWidget {
  final bool isModal;

  const CustomerDirectoryView({super.key, this.isModal = false});

  static Future<void> showModal(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const SizedBox(
        height: 680,
        child: CustomerDirectoryView(isModal: true),
      ),
    );
  }

  @override
  State<CustomerDirectoryView> createState() => _CustomerDirectoryViewState();
}

class _CustomerDirectoryViewState extends State<CustomerDirectoryView> {
  final _customerService = CustomerService();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customerService.fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCustomerDetails(OdooCustomer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: #${customer.customerId} • ${customer.mobile}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0)),
              if (customer.companyName != null && customer.companyName!.isNotEmpty)
                _detailRow('Company / Branch', customer.companyName!, Icons.business_outlined),
              _detailRow('Mobile Phone', customer.mobile.isNotEmpty ? customer.mobile : 'Not registered', Icons.phone_outlined),
              if (customer.email != null && customer.email!.isNotEmpty)
                _detailRow('Email', customer.email!, Icons.email_outlined),
              _detailRow(
                'Opening Balance',
                '₹ ${customer.openBalance.toStringAsFixed(2)}',
                Icons.account_balance_wallet_outlined,
                isHighlight: true,
              ),
              if (customer.outstandingBalance > 0)
                _detailRow(
                  'Outstanding Balance',
                  '₹ ${customer.outstandingBalance.toStringAsFixed(2)}',
                  Icons.receipt_outlined,
                ),
              if (customer.street.isNotEmpty)
                _detailRow('Address', '${customer.street}${customer.street2.isNotEmpty ? ', ${customer.street2}' : ''}',
                    Icons.location_on_outlined),
              if (customer.city.isNotEmpty)
                _detailRow('City & ZIP', '${customer.city}${customer.zip.isNotEmpty ? ' (${customer.zip})' : ''}',
                    Icons.location_city_outlined),
              if (customer.vat.isNotEmpty)
                _detailRow('VAT / Tax ID', customer.vat,
                    Icons.receipt_long_outlined),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                color: isHighlight
                    ? AppColors.primaryBlue
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Customer Directory',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Active Customer Accounts',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Contacts',
            icon: _customerService.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.primaryBlue),
            onPressed: _customerService.isLoading
                ? null
                : () => _customerService.fetchCustomers(forceRefresh: true),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _customerService,
        builder: (context, _) {
          final customers = _customerService.filteredCustomers;

          return Column(
            children: [
              // Search Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _customerService.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search customer name, phone, ID, city...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primaryBlue, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _customerService.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.primaryBlue, width: 1.5),
                    ),
                  ),
                ),
              ),

              // Count Summary Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${customers.length} Customers in CRM',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlueLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Cloud Synced',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Customers List
              Expanded(
                child: customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_search_rounded,
                              size: 48,
                              color: Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No customers found',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: customers.length,
                        itemBuilder: (context, i) {
                          final cust = customers[i];
                          return _buildCustomerCard(cust);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );

    if (widget.isModal) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: content,
      );
    }

    return content;
  }

  Widget _buildCustomerCard(OdooCustomer cust) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showCustomerDetails(cust),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      cust.name.isNotEmpty ? cust.name[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cust.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.iceBlueSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${cust.customerId}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 13,
                                color: cust.mobile.isNotEmpty
                                    ? AppColors.textSecondary
                                    : AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              cust.mobile.isNotEmpty
                                  ? cust.mobile
                                  : 'No phone registered',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: cust.mobile.isNotEmpty
                                    ? AppColors.textSecondary
                                    : AppColors.textMuted,
                                fontStyle: cust.mobile.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (cust.companyName != null &&
                                cust.companyName!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Text('•',
                                  style:
                                      TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlueLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  cust.companyName!,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                            if (cust.city.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Text('•',
                                  style:
                                      TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(width: 8),
                              Text(
                                cust.city,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Opening Balance: ₹ ${cust.openBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
