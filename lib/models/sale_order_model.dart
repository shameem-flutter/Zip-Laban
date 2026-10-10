/// Product item line for Odoo sale order payload
class SaleOrderProductItem {
  final String orderDetId;
  final String orderId;
  final String itemId;
  final String itemCode;
  final String product;
  final String packageName;
  final double unitRate;
  final double price;
  final double discountPercentage;
  final double discount;
  final double qty;
  final double returnQty;
  final String itemPrice;
  final double subPrice;
  final double taxPercentage;
  final double taxAmount;
  final String enteredBy;
  final String entryDate;
  final String arabicName;

  const SaleOrderProductItem({
    required this.orderDetId,
    required this.orderId,
    required this.itemId,
    required this.itemCode,
    required this.product,
    this.packageName = 'PCS',
    required this.unitRate,
    required this.price,
    this.discountPercentage = 0.0,
    this.discount = 0.0,
    this.qty = 1.0,
    this.returnQty = 0.0,
    required this.itemPrice,
    required this.subPrice,
    this.taxPercentage = 15.0,
    required this.taxAmount,
    this.enteredBy = 'ADMIN',
    required this.entryDate,
    this.arabicName = '',
  });

  Map<String, dynamic> toOdooMap() {
    return {
      'OrderDetID': orderDetId,
      'OrderID': orderId,
      'ItemID': itemId,
      'ItemCode': itemCode,
      'product': product,
      'package_name': packageName,
      'UnitRate': unitRate,
      'price': price,
      'DiscountPercentage': discountPercentage,
      'discount': discount,
      'qty': qty,
      'ReturnQty': returnQty,
      'item_price': itemPrice,
      'sub_price': subPrice,
      'TaxPercentage': taxPercentage,
      'TaxAmount': taxAmount,
      'EnteredBy': enteredBy,
      'EntryDate': entryDate,
      'ArabicName': arabicName,
    };
  }
}

/// Request parameters for POST /api/create/sale_order
class CreateSaleOrderInput {
  final int syncOrderId;
  final int tmpId;
  final int companyId;
  final String companyName;
  final String invSequence;
  final String invSequenceId;
  final bool isCreated;
  final bool isUpdated;
  final bool isCreateSync;
  final bool isUpdateSync;
  final String createdAt;
  final String orderId;
  final String orderNo;
  final String orderTrnNo;
  final String saleDate;
  final String saleDateOdoo;
  final String orderDate;
  final String orderType;
  final String orderTypeSlug;
  final String tableNo;
  final String waiterName;
  final double invoiceAmount;
  final double paymentModeCash;
  final double paymentModeCreditCard;
  final double creditTotal;
  final double grandTotal;
  final String cashier;
  final String salespersonName;
  final String entryDate;
  final String deliveryCustomerId;
  final String name;
  final String billClosedBy;
  final String billClosedTime;
  final String customerBillNo;
  final List<SaleOrderProductItem> productData;

  const CreateSaleOrderInput({
    required this.syncOrderId,
    this.tmpId = 1,
    required this.companyId,
    required this.companyName,
    required this.invSequence,
    required this.invSequenceId,
    this.isCreated = true,
    this.isUpdated = false,
    this.isCreateSync = false,
    this.isUpdateSync = false,
    required this.createdAt,
    required this.orderId,
    required this.orderNo,
    required this.orderTrnNo,
    required this.saleDate,
    required this.saleDateOdoo,
    required this.orderDate,
    this.orderType = 'Dine In',
    this.orderTypeSlug = 'dine_in',
    this.tableNo = 'IN01',
    this.waiterName = 'ADMIN',
    required this.invoiceAmount,
    this.paymentModeCash = 0.0,
    this.paymentModeCreditCard = 0.0,
    this.creditTotal = 0.0,
    required this.grandTotal,
    this.cashier = 'ADMIN',
    this.salespersonName = 'ADMIN',
    required this.entryDate,
    this.deliveryCustomerId = '0',
    this.name = '',
    this.billClosedBy = 'ADMIN',
    required this.billClosedTime,
    this.customerBillNo = '0',
    required this.productData,
  });

  Map<String, dynamic> toOdooParams() {
    return {
      'sync_order_id': syncOrderId,
      'TmpID': tmpId,
      'company_id': companyId,
      'CompanyName': companyName,
      'inv_sequence': invSequence,
      'inv_sequence_id': invSequenceId,
      'is_created': isCreated,
      'is_updated': isUpdated,
      'is_create_sync': isCreateSync,
      'is_update_sync': isUpdateSync,
      'CreatedAt': createdAt,
      'OrderID': orderId,
      'OrderNo': orderNo,
      'OrderTrnNo': orderTrnNo,
      'SaleDate': saleDate,
      'sale_date': saleDateOdoo,
      'OrderDate': orderDate,
      'OrderType': orderType,
      'order_type': orderTypeSlug,
      'TableNo': tableNo,
      'WaiterName': waiterName,
      'InvoiceAmount': invoiceAmount,
      'payment_mode_cash': paymentModeCash,
      'payment_mode_creditcard': paymentModeCreditCard,
      'CreditTotal': creditTotal,
      'GrandTotal': grandTotal,
      'Cashier': cashier,
      'salesperson_name': salespersonName,
      'EntryDate': entryDate,
      'DeliveryCustomerID': deliveryCustomerId,
      'name': name,
      'BillClosedBy': billClosedBy,
      'BillClosedTime': billClosedTime,
      'CustomerBillNo': customerBillNo,
      'product_data': productData.map((p) => p.toOdooMap()).toList(),
    };
  }
}

/// Response returned by POST /api/create/sale_order
class CreateSaleOrderResult {
  final bool success;
  final String? message;
  final String? orderId;
  final String? invId;
  final String? error;

  const CreateSaleOrderResult({
    required this.success,
    this.message,
    this.orderId,
    this.invId,
    this.error,
  });

  factory CreateSaleOrderResult.fromOdooResult(Map<String, dynamic> result) {
    final msg = result['message']?.toString() ?? '';
    final orderId = result['order_id']?.toString();
    final invId = result['inv_id']?.toString();
    final explicitSuccess = result['success'] == true;
    final isCreatedMsg = msg.toLowerCase().contains('successfully') ||
        msg.toLowerCase().contains('already created');

    final bool isSuccessful =
        explicitSuccess || orderId != null || isCreatedMsg;

    return CreateSaleOrderResult(
      success: isSuccessful,
      message: msg.isNotEmpty ? msg : (isSuccessful ? 'Sale order synced' : null),
      orderId: orderId,
      invId: invId,
      error: result['error']?.toString(),
    );
  }
}
