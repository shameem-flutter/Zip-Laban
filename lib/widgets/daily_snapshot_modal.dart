import 'package:flutter/material.dart';
import '../models/odoo_order.dart';
import '../services/sale_order_service.dart';
import '../theme/app_colors.dart';

class DailySnapshotModal extends StatelessWidget {
  final String dateText;

  const DailySnapshotModal({
    super.key,
    required this.dateText,
  });

  static Future<void> show(BuildContext context, {required String dateText}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DailySnapshotModal(dateText: dateText),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saleService = SaleOrderService();
    final totalSales = saleService.totalSales;
    final totalOrders = saleService.totalOrderCount;
    final dineInSales = saleService.dineInSales;
    final dineInCount = saleService.dineInOrderCount;
    final pickUpSales = saleService.pickUpSales;
    final pickUpCount = saleService.pickUpOrderCount;
    final avgTicket = totalOrders > 0 ? (totalSales / totalOrders).round() : 0;
    final orders = saleService.getOrdersForOutlet(saleService.activeOutlet);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            const Text(
                              'Daily Snapshot',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlueLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Realtime',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.cardBorder, height: 24),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // High level metrics
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Total Revenue',
                          '₹ ${totalSales.round()}',
                          'Live Orders',
                          true,
                          Icons.currency_rupee_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          'Total Orders',
                          '$totalOrders',
                          'Live Synced',
                          true,
                          Icons.receipt_long_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Avg Ticket Size',
                          '₹ $avgTicket',
                          'Per Receipt',
                          true,
                          Icons.auto_graph_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          'Active Channels',
                          '${(dineInCount > 0 ? 1 : 0) + (pickUpCount > 0 ? 1 : 0)}',
                          'Dine In / Pick Up',
                          true,
                          Icons.storefront_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Order Channel Distribution
                  const Text(
                    'Order Channel Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildChannelRow(
                          'Dine In Orders',
                          '₹ ${dineInSales.round()}',
                          '$dineInCount orders',
                          AppColors.cyanIcon,
                          AppColors.cyanBg,
                        ),
                        const Divider(height: 20),
                        _buildChannelRow(
                          'Pick Up / Takeaway Orders',
                          '₹ ${pickUpSales.round()}',
                          '$pickUpCount orders',
                          AppColors.greenIcon,
                          AppColors.greenBg,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Orders
                  const Text(
                    'Latest Sales Orders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (orders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'No orders fetched yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...orders.take(5).map((ord) => _buildOrderTile(ord)),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    String badge,
    bool isPositive,
    IconData icon,
  ) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 12,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelRow(
    String channel,
    String amount,
    String count,
    Color iconColor,
    Color iconBg,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                channel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTile(OdooOrder ord) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ord.invoiceNumber} • ${ord.partnerName}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${ord.channelDisplay} • ${ord.companyName}',
                  style: const TextStyle(
                    fontSize: 11,
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
  }
}
