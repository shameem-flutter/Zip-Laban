/// Data model representing an invoiced order from Odoo ERP
/// Endpoint: GET /api/list/orders
class OdooOrder {
  final String invoiceNumber;
  final String invoiceDate;
  final String partnerName;
  final String orderType;
  final int companyId;
  final String companyName;
  final double amountUntaxed;
  final double amountTax;
  final double amountTotal;
  final double amountPaid;
  final List<dynamic> payments;

  const OdooOrder({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.partnerName,
    required this.orderType,
    required this.companyId,
    required this.companyName,
    required this.amountUntaxed,
    required this.amountTax,
    required this.amountTotal,
    required this.amountPaid,
    this.payments = const [],
  });

  factory OdooOrder.fromJson(Map<String, dynamic> json) {
    return OdooOrder(
      invoiceNumber: (json['invoice_number'] ?? json['orderId'] ?? '').toString().trim(),
      invoiceDate: (json['invoice_date'] ?? json['sale_date'] ?? '').toString().trim(),
      partnerName: (json['partner_name'] ?? json['customer_name'] ?? 'Customer').toString().trim(),
      orderType: (json['order_type'] ?? json['orderType'] ?? 'dine_in').toString().trim(),
      companyId: json['company_id'] is int
          ? json['company_id'] as int
          : int.tryParse(json['company_id']?.toString() ?? '0') ?? 0,
      companyName: (json['company_name'] ?? json['CompanyName'] ?? '').toString().trim(),
      amountUntaxed: _toDouble(json['amount_untaxed']),
      amountTax: _toDouble(json['amount_tax']),
      amountTotal: _toDouble(json['amount_total'] ?? json['amount'] ?? json['InvoiceAmount']),
      amountPaid: _toDouble(json['amount_paid']),
      payments: json['payments'] is List ? json['payments'] as List : const [],
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() => {
        'invoice_number': invoiceNumber,
        'invoice_date': invoiceDate,
        'partner_name': partnerName,
        'order_type': orderType,
        'company_id': companyId,
        'company_name': companyName,
        'amount_untaxed': amountUntaxed,
        'amount_tax': amountTax,
        'amount_total': amountTotal,
        'amount_paid': amountPaid,
        'payments': payments,
      };

  /// Whether this order is Dine In
  bool get isDineIn => orderType.toLowerCase().contains('dine');

  /// Whether this order is Pick Up / Takeaway
  bool get isPickUp =>
      orderType.toLowerCase().contains('takeaway') ||
      orderType.toLowerCase().contains('pick');

  /// Whether this order is Delivery
  bool get isDelivery => orderType.toLowerCase().contains('deliv');

  /// User-friendly channel display title
  String get channelDisplay {
    if (isDineIn) return 'Dine In';
    if (isDelivery) return 'Delivery';
    return 'Pick Up';
  }

  /// Parsed DateTime (preserving timestamp if available)
  DateTime? get parsedDateTime {
    final dt = DateTime.tryParse(invoiceDate);
    if (dt == null) return null;
    return dt.isUtc ? dt.toLocal() : dt;
  }

  /// Normalized Date (Year, Month, Day) for date comparisons without timezone/hour offsets
  DateTime? get parsedDate {
    final dt = parsedDateTime;
    if (dt == null) return null;
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Status badge label
  String get statusDisplay {
    if (amountPaid >= amountTotal && amountTotal > 0) return 'Completed';
    if (amountPaid > 0) return 'Billed';
    return isDineIn ? 'Served' : 'Ready';
  }

  /// Converts this OdooOrder into map format expected by UI order lists
  Map<String, dynamic> toMap() {
    final prefix = invoiceNumber.startsWith('#') ? '' : '#';
    return {
      'orderId': '$prefix$invoiceNumber',
      'invId': invoiceNumber,
      'amount': amountTotal,
      'orderType': channelDisplay,
      'tableNo': partnerName,
      'companyId': companyId,
      'companyName': companyName,
      'items': '$channelDisplay Invoiced Order',
      'time': invoiceDate,
      'timestamp': invoiceDate,
      'status': statusDisplay,
      'message': 'Odoo Invoiced Order',
    };
  }

  /// Comparator to sort orders latest-first (newest date first, then highest sequence first)
  static int compareLatestFirst(OdooOrder a, OdooOrder b) {
    // 1. Primary: Compare date descending
    final dateA = a.parsedDateTime;
    final dateB = b.parsedDateTime;
    if (dateA != null && dateB != null) {
      final dateComp = dateB.compareTo(dateA);
      if (dateComp != 0) return dateComp;
    } else if (a.invoiceDate != b.invoiceDate) {
      final strComp = b.invoiceDate.compareTo(a.invoiceDate);
      if (strComp != 0) return strComp;
    }

    // 2. Secondary: Compare invoice number / sequence descending
    final numA = _extractSequence(a.invoiceNumber);
    final numB = _extractSequence(b.invoiceNumber);
    if (numA != null && numB != null) {
      return numB.compareTo(numA);
    }

    return b.invoiceNumber.compareTo(a.invoiceNumber);
  }

  static int? _extractSequence(String inv) {
    final digits = inv.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits);
  }

  @override
  String toString() =>
      'OdooOrder(invoice: $invoiceNumber, date: $invoiceDate, companyId: $companyId, branch: $companyName, type: $orderType, total: $amountTotal)';
}
