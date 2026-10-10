import 'package:flutter/material.dart';
import '../models/odoo_order.dart';
import '../models/sales_model.dart';
import '../services/sale_order_service.dart';
import '../theme/app_colors.dart';

class OrdersDetailModal extends StatelessWidget {
  final String categoryTitle;
  final double totalAmount;
  final int orderCount;
  final String metricInfo;
  final OutletInfo? selectedOutlet;

  const OrdersDetailModal({
    super.key,
    required this.categoryTitle,
    required this.totalAmount,
    required this.orderCount,
    required this.metricInfo,
    this.selectedOutlet,
  });

  static Future<void> show(
    BuildContext context, {
    required String categoryTitle,
    required double totalAmount,
    required int orderCount,
    required String metricInfo,
    OutletInfo? selectedOutlet,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => OrdersDetailModal(
        categoryTitle: categoryTitle,
        totalAmount: totalAmount,
        orderCount: orderCount,
        metricInfo: metricInfo,
        selectedOutlet: selectedOutlet,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'served':
      case 'ready':
      case 'ready for pickup':
        return AppColors.primaryBlue;
      case 'billed':
        return AppColors.skyBlue;
      case 'completed':
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'served':
      case 'ready':
      case 'ready for pickup':
        return AppColors.primaryBlueLight;
      case 'billed':
        return AppColors.skyBlueLight;
      case 'completed':
      default:
        return AppColors.iceBlueSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDineIn = categoryTitle.contains('DINE');
    final isDelivery = categoryTitle.contains('DELIV');
    final liveOrders = SaleOrderService().getOrdersByChannel(
      categoryTitle,
      outlet: selectedOutlet,
    );

    final outletName = selectedOutlet?.shortName ?? selectedOutlet?.name;
    final badgeBg = isDineIn
        ? AppColors.cyanBg
        : (isDelivery ? const Color(0xFFFFF4ED) : AppColors.greenBg);
    final badgeTextColor = isDineIn
        ? AppColors.cyanIcon
        : (isDelivery ? const Color(0xFFFB6514) : AppColors.greenIcon);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$categoryTitle Orders',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        outletName != null
                            ? '$outletName • $orderCount Orders • $metricInfo'
                            : '$orderCount Orders Today • $metricInfo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '₹ ${totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(color: AppColors.cardBorder, height: 28),

            // Orders list
            if (liveOrders.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.receipt_outlined,
                        size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 10),
                    Text(
                      selectedOutlet != null
                          ? 'No $categoryTitle orders for ${selectedOutlet!.name}'
                          : 'No orders in this channel yet',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...liveOrders.map((order) {
                final id = (order['orderId'] ?? order['id'] ?? '#WR-001').toString();
                final time = (order['time'] ?? 'Just now').toString();
                final table = (order['tableNo'] ?? order['table'] ?? 'Counter').toString();
                final branch = (order['companyName'] ?? '').toString();
                final items = (order['items'] ?? 'Assorted Items').toString();
                final amt = order['amount'];
                final amtStr = amt is num ? '₹ ${amt.round()}' : (amt?.toString() ?? '₹ 0');
                final status = (order['status'] ?? 'Ready').toString();
                final color = _getStatusColor(status);
                final bgColor = _getStatusBgColor(status);

                final rawInv = (order['invId'] ?? '').toString();
                final odooOrder = SaleOrderService().odooOrders.firstWhere(
                  (o) => o.invoiceNumber == rawInv || '#${o.invoiceNumber}' == id,
                  orElse: () => OdooOrder(
                    invoiceNumber: rawInv.isNotEmpty ? rawInv : id.replaceAll('#', ''),
                    invoiceDate: time,
                    partnerName: table,
                    orderType: categoryTitle,
                    companyId: int.tryParse(selectedOutlet?.id ?? '2') ?? 2,
                    companyName: branch.isNotEmpty ? branch : (selectedOutlet?.name ?? ''),
                    amountUntaxed: (amt is num ? amt.toDouble() : 0.0),
                    amountTax: 0.0,
                    amountTotal: (amt is num ? amt.toDouble() : 0.0),
                    amountPaid: (amt is num ? amt.toDouble() : 0.0),
                  ),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showOrderDetailsSheet(context, odooOrder, order),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      id,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        time,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            table,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (branch.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.storefront_outlined,
                                    size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  branch,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            items,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Total: $amtStr',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                onPressed: () => _showOrderDetailsSheet(
                                    context, odooOrder, order),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.primaryBlue),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  'Details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showOrderDetailsSheet(
    BuildContext context,
    OdooOrder odooOrder,
    Map<String, dynamic> order,
  ) {
    final status = odooOrder.statusDisplay;
    final color = _getStatusColor(status);
    final bgColor = _getStatusBgColor(status);
    final isDine = odooOrder.isDineIn;
    final isDeliv = odooOrder.isDelivery;
    final channelIcon = isDine
        ? Icons.restaurant_rounded
        : (isDeliv
            ? Icons.delivery_dining_rounded
            : Icons.shopping_bag_outlined);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          channelIcon,
                          color: AppColors.primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${odooOrder.invoiceNumber}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${odooOrder.channelDisplay} Invoiced Order',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.storefront_outlined,
                      label: 'Store Branch',
                      value: odooOrder.companyName.isNotEmpty
                          ? odooOrder.companyName
                          : (selectedOutlet?.name ?? 'Kottakkal Branch'),
                    ),
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: 'Customer / Guest',
                      value: odooOrder.partnerName.isNotEmpty
                          ? odooOrder.partnerName
                          : 'Walk-in Customer',
                    ),
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Invoice Date',
                      value: odooOrder.invoiceDate.isNotEmpty
                          ? odooOrder.invoiceDate
                          : 'Today',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Items Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ordered Items',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            (order['items'] ?? '${odooOrder.channelDisplay} Items').toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '₹ ${odooOrder.amountTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Financial Breakdown Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildPriceRow('Untaxed Amount',
                        '₹ ${odooOrder.amountUntaxed.toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    _buildPriceRow('VAT / Tax',
                        '₹ ${odooOrder.amountTax.toStringAsFixed(2)}'),
                    const Divider(height: 16, color: Color(0xFFCBD5E1)),
                    _buildPriceRow(
                      'Grand Total',
                      '₹ ${odooOrder.amountTotal.toStringAsFixed(2)}',
                      isBold: true,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 6),
                    _buildPriceRow(
                      'Amount Paid',
                      '₹ ${odooOrder.amountPaid.toStringAsFixed(2)}',
                      color: odooOrder.amountPaid > 0
                          ? AppColors.greenIcon
                          : AppColors.textSecondary,
                    ),
                    if (odooOrder.amountTotal > odooOrder.amountPaid) ...[
                      const SizedBox(height: 6),
                      _buildPriceRow(
                        'Balance Due',
                        '₹ ${(odooOrder.amountTotal - odooOrder.amountPaid).toStringAsFixed(2)}',
                        color: const Color(0xFFDC2626),
                        isBold: true,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildPriceRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 12.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
