import 'package:flutter/material.dart';
import '../models/odoo_product.dart';
import '../models/sale_order_model.dart';
import '../models/sales_model.dart';
import '../services/product_service.dart';
import '../services/sale_order_service.dart';
import '../services/salesperson_service.dart';
import '../theme/app_colors.dart';

class CreateSaleOrderModal extends StatefulWidget {
  final OutletInfo outlet;

  const CreateSaleOrderModal({super.key, required this.outlet});

  static Future<void> show(BuildContext context, {required OutletInfo outlet}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CreateSaleOrderModal(outlet: outlet),
    );
  }

  @override
  State<CreateSaleOrderModal> createState() => _CreateSaleOrderModalState();
}

class _CreateSaleOrderModalState extends State<CreateSaleOrderModal> {
  final _saleOrderService = SaleOrderService();
  final _productService = ProductService();
  final _salespersonService = SalespersonService();

  String _selectedOrderType = 'Dine In';
  String _selectedPaymentMode = 'Credit Card';
  final _tableController = TextEditingController(text: 'IN01');
  final _waiterController = TextEditingController(text: 'ADMIN');

  // Selected products with quantity
  final Map<String, int> _cartQuantities = {};
  List<OdooProduct> _availableProducts = [];

  @override
  void initState() {
    super.initState();
    _initCart();
    _salespersonService.fetchSalespersons();
  }

  void _initCart() {
    _availableProducts = _productService.products;
    if (_availableProducts.isEmpty) {
      _productService.fetchProducts().then((_) {
        if (mounted) {
          setState(() {
            _availableProducts = _productService.products;
            _prefillDefaultItem();
          });
        }
      });
    } else {
      _prefillDefaultItem();
    }
  }

  void _prefillDefaultItem() {
    if (_availableProducts.isNotEmpty) {
      final first = _availableProducts.first;
      _cartQuantities[first.itemId] = 1;
    }
  }

  @override
  void dispose() {
    _tableController.dispose();
    _waiterController.dispose();
    super.dispose();
  }

  double get _subtotal {
    double sum = 0.0;
    for (final p in _availableProducts) {
      final qty = _cartQuantities[p.itemId] ?? 0;
      if (qty > 0) {
        sum += (p.price > 0 ? p.price : 22.0) * qty;
      }
    }
    return sum;
  }

  double get _vatAmount => (_subtotal * 0.15 * 100).round() / 100;
  double get _grandTotal => _subtotal;


  Future<void> _submitSaleOrder() async {
    final selectedItems = _availableProducts
        .where((p) => (_cartQuantities[p.itemId] ?? 0) > 0)
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 item to create an order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final orderNum = (now.millisecondsSinceEpoch ~/ 1000) % 90000 + 10000;
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final dateOnly =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 00:00:00';

    final List<SaleOrderProductItem> productLines = [];
    for (int i = 0; i < selectedItems.length; i++) {
      final p = selectedItems[i];
      final qty = (_cartQuantities[p.itemId] ?? 1).toDouble();
      final unitRate = p.price > 0 ? p.price : 22.0;
      final subPrice = unitRate * qty;
      final tax = (subPrice * 0.15 * 100).round() / 100;

      productLines.add(
        SaleOrderProductItem(
          orderDetId: '${orderNum + i + 1}',
          orderId: '$orderNum',
          itemId: p.itemId.isNotEmpty ? p.itemId : '71366',
          itemCode: p.barcode.isNotEmpty ? p.barcode : '1000000024',
          product: p.name,
          packageName: p.uom.isNotEmpty ? p.uom : 'PCS',
          unitRate: unitRate,
          price: unitRate,
          discountPercentage: 0.0,
          discount: 0.0,
          qty: qty,
          returnQty: 0.0,
          itemPrice: unitRate.toStringAsFixed(3),
          subPrice: subPrice,
          taxPercentage: 15.0,
          taxAmount: tax,
          enteredBy: 'ADMIN',
          entryDate: dateStr,
          arabicName: p.arabicName ?? '',
        ),
      );
    }

    final isCash = _selectedPaymentMode == 'Cash';
    final companyIdInt = int.tryParse(widget.outlet.id) ?? 2;

    final input = CreateSaleOrderInput(
      syncOrderId: orderNum,
      tmpId: 1,
      companyId: companyIdInt,
      companyName: widget.outlet.name,
      invSequence: '$orderNum',
      invSequenceId: '$orderNum',
      isCreated: true,
      isUpdated: false,
      isCreateSync: false,
      isUpdateSync: false,
      createdAt: dateStr,
      orderId: '$orderNum',
      orderNo: '$orderNum',
      orderTrnNo: '$orderNum',
      saleDate: dateOnly,
      saleDateOdoo: dateOnly,
      orderDate: dateStr,
      orderType: _selectedOrderType,
      orderTypeSlug: _selectedOrderType.toLowerCase().replaceAll(' ', '_'),
      tableNo: _tableController.text.trim(),
      waiterName: _waiterController.text.trim(),
      invoiceAmount: _grandTotal,
      paymentModeCash: isCash ? _grandTotal : 0.0,
      paymentModeCreditCard: isCash ? 0.0 : _grandTotal,
      creditTotal: 0.0,
      grandTotal: _grandTotal,
      cashier: 'ADMIN',
      salespersonName: 'ADMIN',
      entryDate: dateStr,
      deliveryCustomerId: '0',
      name: '',
      billClosedBy: 'ADMIN',
      billClosedTime: dateStr,
      customerBillNo: '0',
      productData: productLines,
    );

    final res = await _saleOrderService.createSaleOrder(input);

    if (!mounted) return;

    if (res.success) {
      Navigator.pop(context);
      _showSuccessDialog(res, orderNum);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? res.error ?? 'Failed to sync sale order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(CreateSaleOrderResult res, int orderNum) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 28),
            SizedBox(width: 10),
            Text('Sale Order Synced',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                res.message ?? 'Order created successfully in Odoo ERP',
                style: const TextStyle(
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _infoRow('Odoo Order ID', res.orderId ?? 'ORD-$orderNum'),
            const Divider(height: 16),
            _infoRow('Invoice Sequence', res.invId ?? '$orderNum'),
            const Divider(height: 16),
            _infoRow('Outlet Branch', widget.outlet.name),
            const Divider(height: 16),
            _infoRow('Total Amount', '₹ ${_grandTotal.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Great, Done'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            const SizedBox(height: 14),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New POS Sale Order',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Direct Counter POS Invoicing',
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
            const SizedBox(height: 12),

            // Branch Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlueLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.iceBlue),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded,
                      color: AppColors.primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.outlet.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlueDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ID: ${widget.outlet.id}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Scrollable Form & Items
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Order Type Selection
                  const Text('Order Type',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _orderTypeChip('Dine In', Icons.restaurant_rounded),
                      const SizedBox(width: 8),
                      _orderTypeChip('Take Away', Icons.takeout_dining_rounded),
                      const SizedBox(width: 8),
                      _orderTypeChip('Delivery', Icons.delivery_dining_rounded),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Table & Waiter Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tableController,
                          decoration: InputDecoration(
                            labelText: 'Table / Token No',
                            labelStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.table_restaurant_outlined,
                                size: 18),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _waiterController,
                          decoration: InputDecoration(
                            labelText: 'Cashier / Waiter',
                            labelStyle: const TextStyle(fontSize: 12),
                            prefixIcon:
                                const Icon(Icons.person_outline, size: 18),
                            suffixIcon: PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down_rounded,
                                  size: 20),
                              tooltip: 'Select Staff Member',
                              onSelected: (val) {
                                setState(() => _waiterController.text = val);
                              },
                              itemBuilder: (ctx) {
                                return _salespersonService.salespersons
                                    .map(
                                      (s) => PopupMenuItem<String>(
                                        value: s.name,
                                        child: Text('${s.name} (#${s.id})'),
                                      ),
                                    )
                                    .toList();
                              },
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Payment Mode
                  const Text('Payment Mode',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _paymentModeChip('Credit Card', Icons.credit_card_rounded),
                      const SizedBox(width: 8),
                      _paymentModeChip('Cash', Icons.payments_outlined),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Menu Items Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Products',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_availableProducts.length} live items',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._availableProducts.map((product) {
                    final qty = _cartQuantities[product.itemId] ?? 0;
                    final price = product.price > 0 ? product.price : 22.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: qty > 0
                            ? AppColors.primaryBlueLight
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: qty > 0
                              ? AppColors.primaryBlue
                              : AppColors.cardBorder,
                          width: qty > 0 ? 1.2 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: qty > 0
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹ ${price.toStringAsFixed(2)} • ${product.uom.isNotEmpty ? product.uom : 'PCS'}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Qty Selector
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 28, minHeight: 28),
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      if (qty > 0) {
                                        _cartQuantities[product.itemId] =
                                            qty - 1;
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 28, minHeight: 28),
                                  icon: const Icon(Icons.add,
                                      size: 16, color: AppColors.primaryBlue),
                                  onPressed: () {
                                    setState(() {
                                      _cartQuantities[product.itemId] =
                                          qty + 1;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bill Summary & Sync Button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Total (Incl. VAT ₹${_vatAmount.toStringAsFixed(2)})',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹ ${_grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saleOrderService.isLoading
                          ? null
                          : _submitSaleOrder,
                      icon: _saleOrderService.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.receipt_long_rounded),
                      label: Text(
                        _saleOrderService.isLoading
                            ? 'Processing Order...'
                            : 'Confirm & Print Order',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTypeChip(String label, IconData icon) {
    final isSelected = _selectedOrderType == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedOrderType = label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentModeChip(String label, IconData icon) {
    final isSelected = _selectedPaymentMode == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMode = label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlueLight : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder,
              width: isSelected ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
