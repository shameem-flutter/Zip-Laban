import 'package:flutter/material.dart';
import '../models/sales_model.dart';
import '../services/sale_order_service.dart';
import '../services/salesperson_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/orders_detail_modal.dart';
import 'product_catalog_view.dart';

class OperationView extends StatelessWidget {
  final OutletInfo outlet;

  const OperationView({super.key, required this.outlet});

  @override
  Widget build(BuildContext context) {
    final saleService = SaleOrderService();
    final staffCount = SalespersonService().salespersons.length;
    final liveOrders = saleService.getOrdersForOutlet(outlet);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 24, borderRadius: 6),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Live Operations • ${outlet.shortName}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Menu Catalog',
            icon: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryBlue),
            onPressed: () => ProductCatalogView.showModal(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Operational Status Grid
          Row(
            children: [
              Expanded(
                child: _statusCard(
                  'Active Orders',
                  '${liveOrders.length} Invoiced',
                  'Active Invoices',
                  AppColors.primaryBlueLight,
                  AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statusCard(
                  'Staff On Shift',
                  '$staffCount Active',
                  'On Duty Staff',
                  AppColors.greenBg,
                  AppColors.greenIcon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statusCard(
                  'Dine In Queue',
                  '${saleService.getDineInCountForOutlet(outlet)} Tables',
                  'Counter & Floor',
                  AppColors.cyanBg,
                  AppColors.cyanIcon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statusCard(
                  'Pick Up Queue',
                  '${saleService.getPickUpCountForOutlet(outlet)} Orders',
                  'Ready at Counter',
                  AppColors.orangeBg,
                  AppColors.orangeIcon,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Live Kitchen / Active Orders Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Counter Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  OrdersDetailModal.show(
                    context,
                    categoryTitle: 'ALL ORDERS',
                    totalAmount: saleService.getTotalSalesForOutlet(outlet),
                    orderCount: liveOrders.length,
                    metricInfo: 'Live Invoiced Receipts',
                    selectedOutlet: outlet,
                  );
                },
                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (liveOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Center(
                child: Column(
                  children: const [
                    Icon(Icons.receipt_long_rounded, size: 36, color: AppColors.textMuted),
                    SizedBox(height: 8),
                    Text(
                      'No active orders for this branch',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...liveOrders.take(5).map((ord) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: ord.isDineIn ? AppColors.cyanBg : AppColors.greenBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        ord.isDineIn ? Icons.restaurant_rounded : Icons.shopping_bag_outlined,
                        color: ord.isDineIn ? AppColors.cyanIcon : AppColors.greenIcon,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ord.invoiceNumber} • ${ord.partnerName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ord.channelDisplay} • ${ord.invoiceDate}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹ ${ord.amountTotal.round()}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statusCard(String title, String main, String sub, Color bg, Color textC) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            main,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textC,
            ),
          ),
        ],
      ),
    );
  }
}
