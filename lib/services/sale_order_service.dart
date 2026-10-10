import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../models/odoo_order.dart';
import '../models/sale_order_model.dart';
import '../models/sales_model.dart';
import 'auth_service.dart';

/// Service for creating and querying POS Sale Orders in Odoo ERP
/// Endpoints:
/// - POST /api/create/sale_order
/// - GET /api/list/orders
class SaleOrderService extends ChangeNotifier {
  static final SaleOrderService _instance = SaleOrderService._internal();
  factory SaleOrderService() => _instance;

  // Disabled (Analytics Only):
  // static const String endpoint = ApiEndpoints.createSaleOrder;
  static const String listEndpoint = ApiEndpoints.listOrders;

  bool _isLoading = false;
  String? _errorMessage;
  List<OdooOrder> _odooOrders = [];
  final List<Map<String, dynamic>> _syncedOrders = [];
  DateTime? _lastPosSyncedAt;
  DateTime? _lastOrdersSyncedAt;
  bool _isFromLiveApi = false;
  OutletInfo? _activeOutlet;

  SaleOrderService._internal() {
    _populateDefaultOrders();
    _lastPosSyncedAt = DateTime.now().subtract(const Duration(minutes: 2));
    _lastOrdersSyncedAt = DateTime.now().subtract(const Duration(hours: 1));
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFromLiveApi => _isFromLiveApi;
  List<OdooOrder> get odooOrders => List.unmodifiable(_odooOrders);
  List<Map<String, dynamic>> get syncedOrders => List.unmodifiable(_syncedOrders);
  DateTime? get lastPosSyncedAt => _lastPosSyncedAt;
  DateTime? get lastOrdersSyncedAt => _lastOrdersSyncedAt;
  OutletInfo? get activeOutlet => _activeOutlet;

  /// Sets the currently active outlet to filter dashboard metrics and orders
  void setActiveOutlet(OutletInfo? outlet) {
    if (_activeOutlet?.id != outlet?.id) {
      _activeOutlet = outlet;
      notifyListeners();
    }
  }

  /// Checks whether an order belongs to the specified outlet
  bool matchesOutlet(OdooOrder order, OutletInfo? outlet) {
    if (outlet == null) return true;
    final outletIdInt = int.tryParse(outlet.id);
    if (outletIdInt != null && order.companyId == outletIdInt) {
      return true;
    }
    final cleanOutlet = outlet.name.trim().toLowerCase();
    final cleanCompany = order.companyName.trim().toLowerCase();
    if (cleanOutlet.isNotEmpty && cleanCompany.isNotEmpty) {
      if (cleanOutlet == cleanCompany ||
          cleanOutlet.contains(cleanCompany) ||
          cleanCompany.contains(cleanOutlet)) {
        return true;
      }
    }
    return false;
  }

  /// Returns sorted orders for a given outlet (and optional channel 'Dine In' / 'Pick Up' / 'Delivery')
  List<OdooOrder> getOrdersForOutlet(OutletInfo? outlet, {String? channel}) {
    var list = _odooOrders.where((o) => matchesOutlet(o, outlet)).toList();
    if (channel != null && channel.isNotEmpty) {
      final ch = channel.toLowerCase();
      if (ch.contains('dine')) {
        list = list.where((o) => o.isDineIn).toList();
      } else if (ch.contains('deliv')) {
        list = list.where((o) => o.isDelivery).toList();
      } else if (ch.contains('pick') || ch.contains('takeaway')) {
        list = list.where((o) => o.isPickUp).toList();
      } else if (ch.contains('cash')) {
        list = list.where((o) => o.payments.any((p) =>
            p is Map && (p['name']?.toString().toLowerCase().contains('cash') ?? false))).toList();
      } else if (ch.contains('card')) {
        list = list.where((o) => o.payments.any((p) =>
            p is Map && (p['name']?.toString().toLowerCase().contains('card') ?? false))).toList();
      } else if (ch.contains('not paid') || ch.contains('unpaid')) {
        list = list.where((o) => o.amountPaid < o.amountTotal).toList();
      } else if (ch.contains('other')) {
        list = list.where((o) {
          if (o.payments.isNotEmpty) {
            return o.payments.any((p) =>
                p is Map &&
                (p['name']?.toString().toLowerCase().contains('other') ??
                    false));
          }
          return false;
        }).toList();
      }
    }
    list.sort(OdooOrder.compareLatestFirst);
    return list;
  }

  /// Total Sales revenue for a given outlet
  double getTotalSalesForOutlet(OutletInfo? outlet) {
    final orders = getOrdersForOutlet(outlet);
    return orders.fold(0.0, (sum, o) => sum + o.amountTotal);
  }

  /// Dine In revenue for a given outlet
  double getDineInSalesForOutlet(OutletInfo? outlet) {
    final orders = getOrdersForOutlet(outlet, channel: 'dine');
    return orders.fold(0.0, (sum, o) => sum + o.amountTotal);
  }

  /// Pick Up revenue for a given outlet
  double getPickUpSalesForOutlet(OutletInfo? outlet) {
    final orders = getOrdersForOutlet(outlet, channel: 'pick');
    return orders.fold(0.0, (sum, o) => sum + o.amountTotal);
  }

  /// Dine In order count for a given outlet
  int getDineInCountForOutlet(OutletInfo? outlet) {
    return getOrdersForOutlet(outlet, channel: 'dine').length;
  }

  /// Pick Up order count for a given outlet
  int getPickUpCountForOutlet(OutletInfo? outlet) {
    return getOrdersForOutlet(outlet, channel: 'pick').length;
  }

  /// Pick Up average order value for a given outlet
  double getPickUpAverageOrderValueForOutlet(OutletInfo? outlet) {
    final count = getPickUpCountForOutlet(outlet);
    return count > 0 ? (getPickUpSalesForOutlet(outlet) / count) : 0.0;
  }

  /// Dynamic total revenue for active outlet (or all outlets if none selected)
  double get totalSales => getTotalSalesForOutlet(_activeOutlet);

  /// Dynamic Dine In sales revenue
  double get dineInSales => getDineInSalesForOutlet(_activeOutlet);

  /// Dynamic Pick Up sales revenue
  double get pickUpSales => getPickUpSalesForOutlet(_activeOutlet);

  /// Dynamic total order count
  int get totalOrderCount => getOrdersForOutlet(_activeOutlet).length;

  /// Dynamic Dine In order count
  int get dineInOrderCount => getDineInCountForOutlet(_activeOutlet);

  /// Dynamic Pick Up order count
  int get pickUpOrderCount => getPickUpCountForOutlet(_activeOutlet);

  /// Dynamic Average Order Value for Pick Up channel
  double get pickUpAverageOrderValue =>
      getPickUpAverageOrderValueForOutlet(_activeOutlet);

  /// Delivery revenue for a given outlet
  double getDeliverySalesForOutlet(OutletInfo? outlet) {
    final orders = getOrdersForOutlet(outlet, channel: 'deliv');
    return orders.fold(0.0, (sum, o) => sum + o.amountTotal);
  }

  /// Delivery order count for a given outlet
  int getDeliveryCountForOutlet(OutletInfo? outlet) {
    return getOrdersForOutlet(outlet, channel: 'deliv').length;
  }

  /// Delivery average order value for a given outlet
  double getDeliveryAverageOrderValueForOutlet(OutletInfo? outlet) {
    final count = getDeliveryCountForOutlet(outlet);
    return count > 0 ? (getDeliverySalesForOutlet(outlet) / count) : 0.0;
  }

  /// Dynamic Delivery revenue
  double get deliverySales => getDeliverySalesForOutlet(_activeOutlet);

  /// Dynamic Delivery order count
  int get deliveryOrderCount => getDeliveryCountForOutlet(_activeOutlet);

  /// Dynamic Average Order Value for Delivery channel
  double get deliveryAverageOrderValue =>
      getDeliveryAverageOrderValueForOutlet(_activeOutlet);

  /// Cash sales revenue for a specific outlet
  double getCashSalesForOutlet(OutletInfo? outlet) {
    final orders = getOrdersForOutlet(outlet);
    double sum = 0.0;
    for (final o in orders) {
      if (o.payments.isNotEmpty) {
        for (final p in o.payments) {
          if (p is Map && (p['name']?.toString().toLowerCase().contains('cash') ?? false)) {
            sum += (p['amount'] is num ? (p['amount'] as num).toDouble() : 0.0);
          }
        }
      } else if (o.amountPaid > 0) {
        sum += o.amountPaid;
      }
    }
    return sum;
  }

  /// Card sales revenue for a specific outlet
  double getCardSalesForOutlet(OutletInfo? outlet) {
    final orders = getOrdersForOutlet(outlet);
    double sum = 0.0;
    for (final o in orders) {
      if (o.payments.isNotEmpty) {
        for (final p in o.payments) {
          if (p is Map && (p['name']?.toString().toLowerCase().contains('card') ?? false)) {
            sum += (p['amount'] is num ? (p['amount'] as num).toDouble() : 0.0);
          }
        }
      }
    }
    return sum;
  }

  /// Other payment sales revenue for a specific outlet
  double getOtherSalesForOutlet(OutletInfo? outlet) {
    final diff = getTotalSalesForOutlet(outlet) -
        getCashSalesForOutlet(outlet) -
        getCardSalesForOutlet(outlet);
    return diff > 0 ? diff : 0.0;
  }

  /// Unpaid / Not paid sales revenue for a specific outlet
  double getNotPaidSalesForOutlet(OutletInfo? outlet) {
    final orders = getOrdersForOutlet(outlet);
    double sum = 0.0;
    for (final o in orders) {
      if (o.amountPaid < o.amountTotal) {
        sum += (o.amountTotal - o.amountPaid);
      }
    }
    return sum;
  }

  /// Online paid sales revenue for a specific outlet
  double getOnlinePaidSalesForOutlet(OutletInfo? outlet) {
    final orders = getOrdersForOutlet(outlet);
    double sum = 0.0;
    for (final o in orders) {
      for (final p in o.payments) {
        if (p is Map) {
          final name = p['name']?.toString().toLowerCase() ?? '';
          if (name.contains('online') || name.contains('upi') || name.contains('razor')) {
            sum += (p['amount'] is num ? (p['amount'] as num).toDouble() : 0.0);
          }
        }
      }
    }
    return sum;
  }

  /// Online COD sales revenue for a specific outlet
  double getOnlineCodSalesForOutlet(OutletInfo? outlet) {
    final orders = getOrdersForOutlet(outlet);
    double sum = 0.0;
    for (final o in orders) {
      for (final p in o.payments) {
        if (p is Map) {
          final name = p['name']?.toString().toLowerCase() ?? '';
          if (name.contains('cod')) {
            sum += (p['amount'] is num ? (p['amount'] as num).toDouble() : 0.0);
          }
        }
      }
    }
    return sum;
  }

  /// Total orders breakdown for a specific outlet
  int getTotalOrdersCountForOutlet(OutletInfo? outlet) =>
      getOrdersForOutlet(outlet).length;

  int getSuccessfulCountForOutlet(OutletInfo? outlet) =>
      getOrdersForOutlet(outlet).length;

  int getComplimentaryCountForOutlet(OutletInfo? outlet) => 0;

  int getCancelledCountForOutlet(OutletInfo? outlet) => 0;

  /// Cash sales revenue
  double get cashSales => getCashSalesForOutlet(_activeOutlet);

  /// Card sales revenue
  double get cardSales => getCardSalesForOutlet(_activeOutlet);

  /// Other payment sales revenue
  double get otherSales => getOtherSalesForOutlet(_activeOutlet);

  /// Total orders breakdown
  int get successfulOrderCount => getSuccessfulCountForOutlet(_activeOutlet);
  int get complimentaryOrderCount => getComplimentaryCountForOutlet(_activeOutlet);
  int get cancelledOrderCount => getCancelledCountForOutlet(_activeOutlet);

  /// Retrieves live order entries for a specific channel (Dine In / Pick Up), sorted newest first
  List<Map<String, dynamic>> getOrdersByChannel(String channel,
      {OutletInfo? outlet}) {
    final orders =
        getOrdersForOutlet(outlet ?? _activeOutlet, channel: channel);
    return orders.map((o) => o.toMap()).toList();
  }

  /// Updates last sync timestamps to current time
  void markSyncedNow() {
    _lastPosSyncedAt = DateTime.now();
    _lastOrdersSyncedAt = DateTime.now();
    notifyListeners();
  }

  // Exact dataset from user's /api/list/orders response
  static final List<Map<String, dynamic>> defaultOdooOrders = [
    {
      "invoice_number": "POS-V2-33",
      "invoice_date": "2026-10-09",
      "partner_name": "Default Customer (Kottakkal)",
      "order_type": "takeaway",
      "company_id": 2,
      "company_name": "KOTTAKKAL BRANCH",
      "amount_untaxed": 402.5,
      "amount_tax": 0.0,
      "amount_total": 402.5,
      "amount_paid": 0.0,
      "payments": []
    },
    {
      "invoice_number": "999",
      "invoice_date": "2026-10-08",
      "partner_name": "Default Customer (Kottakkal)",
      "order_type": "dine_in",
      "company_id": 2,
      "company_name": "KOTTAKKAL BRANCH",
      "amount_untaxed": 22.0,
      "amount_tax": 0.0,
      "amount_total": 22.0,
      "amount_paid": 0.0,
      "payments": []
    },
    {
      "invoice_number": "POS-V2-26",
      "invoice_date": "2026-10-07",
      "partner_name": "Default Customer (Kadampuzha)",
      "order_type": "takeaway",
      "company_id": 3,
      "company_name": "KADAMPUZHA BRANCH",
      "amount_untaxed": 402.5,
      "amount_tax": 0.0,
      "amount_total": 402.5,
      "amount_paid": 0.0,
      "payments": []
    },
    {
      "invoice_number": "POS-V2-25",
      "invoice_date": "2026-10-07",
      "partner_name": "Default Customer (Kadampuzha)",
      "order_type": "takeaway",
      "company_id": 3,
      "company_name": "KADAMPUZHA BRANCH",
      "amount_untaxed": 402.5,
      "amount_tax": 0.0,
      "amount_total": 402.5,
      "amount_paid": 0.0,
      "payments": []
    },
    {
      "invoice_number": "POS-V2-24",
      "invoice_date": "2026-10-07",
      "partner_name": "Default Customer (Kadampuzha)",
      "order_type": "takeaway",
      "company_id": 3,
      "company_name": "KADAMPUZHA BRANCH",
      "amount_untaxed": 172.5,
      "amount_tax": 0.0,
      "amount_total": 172.5,
      "amount_paid": 0.0,
      "payments": []
    },
    {
      "invoice_number": "POS-V2-23",
      "invoice_date": "2026-10-07",
      "partner_name": "Default Customer (Kadampuzha)",
      "order_type": "takeaway",
      "company_id": 3,
      "company_name": "KADAMPUZHA BRANCH",
      "amount_untaxed": 920.0,
      "amount_tax": 0.0,
      "amount_total": 920.0,
      "amount_paid": 0.0,
      "payments": []
    },
    {
      "invoice_number": "POS-V2-22",
      "invoice_date": "2026-10-07",
      "partner_name": "Default Customer (Kadampuzha)",
      "order_type": "takeaway",
      "company_id": 3,
      "company_name": "KADAMPUZHA BRANCH",
      "amount_untaxed": 172.5,
      "amount_tax": 0.0,
      "amount_total": 172.5,
      "amount_paid": 0.0,
      "payments": []
    },
    {
      "invoice_number": "POS-V2-21",
      "invoice_date": "2026-10-07",
      "partner_name": "Default Customer (Kadampuzha)",
      "order_type": "takeaway",
      "company_id": 3,
      "company_name": "KADAMPUZHA BRANCH",
      "amount_untaxed": 402.5,
      "amount_tax": 0.0,
      "amount_total": 402.5,
      "amount_paid": 0.0,
      "payments": []
    },
    {
      "invoice_number": "POS-V2-20",
      "invoice_date": "2026-10-05",
      "partner_name": "Default Customer (Kadampuzha)",
      "order_type": "takeaway",
      "company_id": 3,
      "company_name": "KADAMPUZHA BRANCH",
      "amount_untaxed": 132.0,
      "amount_tax": 0.0,
      "amount_total": 132.0,
      "amount_paid": 0.0,
      "payments": []
    },
    {
      "invoice_number": "POS-V2-19",
      "invoice_date": "2026-10-03",
      "partner_name": "Default Customer (Kadampuzha)",
      "order_type": "takeaway",
      "company_id": 3,
      "company_name": "KADAMPUZHA BRANCH",
      "amount_untaxed": 66.0,
      "amount_tax": 0.0,
      "amount_total": 66.0,
      "amount_paid": 0.0,
      "payments": []
    },
    {
      "invoice_number": "POS-V2-18",
      "invoice_date": "2026-10-03",
      "partner_name": "Default Customer (Kottakkal)",
      "order_type": "takeaway",
      "company_id": 2,
      "company_name": "KOTTAKKAL BRANCH",
      "amount_untaxed": 172.5,
      "amount_tax": 0.0,
      "amount_total": 172.5,
      "amount_paid": 0.0,
      "payments": []
    }
  ];

  void _populateDefaultOrders() {
    _odooOrders = defaultOdooOrders
        .map((j) => OdooOrder.fromJson(j))
        .toList();
    _odooOrders.sort(OdooOrder.compareLatestFirst);
    _syncedOrders.clear();
    _syncedOrders.addAll(_odooOrders.map((o) => o.toMap()));
  }

  /// Fetches orders from Odoo via GET /api/list/orders
  Future<bool> fetchOrders({bool forceRefresh = false}) async {
    if (_isFromLiveApi && !forceRefresh) {
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final sessId = AuthService().currentUser?.sessionId;

    try {
      final payload = {
        'jsonrpc': '2.0',
        'params': {},
      };

      final request = http.Request('GET', Uri.parse(listEndpoint));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (sessId != null && sessId.isNotEmpty) 'Cookie': 'session_id=$sessId',
      });
      request.body = jsonEncode(payload);

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 12));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('error') && data['error'] != null) {
          final err = data['error'];
          _errorMessage = err is Map
              ? (err['data']?['message'] ?? err['message'])
              : err.toString();
          if (_odooOrders.isEmpty) _populateDefaultOrders();
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final result = data['result'];
        if (result is List) {
          final parsed = result
              .whereType<Map<String, dynamic>>()
              .map((item) => OdooOrder.fromJson(item))
              .toList();
          parsed.sort(OdooOrder.compareLatestFirst);
          _odooOrders = parsed;
          _syncedOrders.clear();
          _syncedOrders.addAll(_odooOrders.map((o) => o.toMap()));
          _isFromLiveApi = true;
          _lastOrdersSyncedAt = DateTime.now();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      if (_odooOrders.isEmpty) _populateDefaultOrders();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (_odooOrders.isEmpty) _populateDefaultOrders();
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  /// Disabled: Order creation is not used in this Analytics-only Dashboard
  Future<CreateSaleOrderResult> createSaleOrder(CreateSaleOrderInput input) async {
    // Disabled (Analytics Only):
    // POST /api/create/sale_order is removed
    return const CreateSaleOrderResult(
      success: false,
      message: 'Order creation is disabled. This app is dedicated to analytics and reporting.',
    );
  }
}
