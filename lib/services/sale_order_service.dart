import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';
import '../models/odoo_order.dart';
import '../models/sales_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Preset types for date filtering
enum DateFilterPreset {
  today,
  yesterday,
  last7Days,
  thisMonth,
  custom,
  all,
}

/// Service for querying POS Sale Orders in Odoo ERP (Analytics)
/// Endpoints:
/// - GET /api/list/orders
class SaleOrderService extends ChangeNotifier {
  static final SaleOrderService _instance = SaleOrderService._internal();
  factory SaleOrderService() => _instance;

  static const String listEndpoint = ApiEndpoints.listOrders;
  static const String _cachedOrdersKey = 'waslasoft_cached_orders';
  static const String _cachedOrdersSyncTimeKey = 'waslasoft_cached_orders_sync_time';

  bool _isLoading = false;
  String? _errorMessage;
  List<OdooOrder> _odooOrders = [];
  final List<Map<String, dynamic>> _syncedOrders = [];
  DateTime? _lastPosSyncedAt;
  DateTime? _lastOrdersSyncedAt;
  bool _isFromLiveApi = false;
  bool _isUsingCachedData = false;
  bool _isSessionExpired = false;
  OutletInfo? _activeOutlet;

  // Date Filter State
  DateFilterPreset _dateFilterPreset = DateFilterPreset.today;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _dateFilterLabel = 'Today';

  SaleOrderService._internal() {
    _applyPresetDates(DateFilterPreset.today);
  }

  /// Restores cached orders from persistent storage on startup
  Future<void> restoreCachedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cachedOrdersKey);
      final syncTimeStr = prefs.getString(_cachedOrdersSyncTimeKey);
      if (jsonStr != null && jsonStr.isNotEmpty && _odooOrders.isEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        final restored = list
            .whereType<Map<String, dynamic>>()
            .map((item) => OdooOrder.fromJson(item))
            .toList();
        if (restored.isNotEmpty) {
          restored.sort(OdooOrder.compareLatestFirst);
          _odooOrders = restored;
          _syncedOrders.clear();
          _syncedOrders.addAll(_odooOrders.map((o) => o.toMap()));
          _isUsingCachedData = true;
          if (syncTimeStr != null) {
            _lastOrdersSyncedAt = DateTime.tryParse(syncTimeStr);
            _lastPosSyncedAt = _lastOrdersSyncedAt;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error restoring cached orders: $e');
    }
  }

  Future<void> _saveOrdersToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _odooOrders.map((o) => o.toMap()).toList();
      await prefs.setString(_cachedOrdersKey, jsonEncode(list));
      if (_lastOrdersSyncedAt != null) {
        await prefs.setString(
            _cachedOrdersSyncTimeKey, _lastOrdersSyncedAt!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error caching orders: $e');
    }
  }

  void clear() {
    _odooOrders = [];
    _syncedOrders.clear();
    _isLoading = false;
    _errorMessage = null;
    _lastPosSyncedAt = null;
    _lastOrdersSyncedAt = null;
    _isFromLiveApi = false;
    _isUsingCachedData = false;
    _isSessionExpired = false;
    _activeOutlet = null;
    _applyPresetDates(DateFilterPreset.today);
    notifyListeners();
  }

  @visibleForTesting
  void setOrdersForTesting(List<OdooOrder> orders) {
    _odooOrders = List.from(orders);
    _syncedOrders.clear();
    _syncedOrders.addAll(_odooOrders.map((o) => o.toMap()));
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFromLiveApi => _isFromLiveApi;
  bool get isUsingCachedData => _isUsingCachedData;
  bool get isSessionExpired => _isSessionExpired;
  List<OdooOrder> get odooOrders => List.unmodifiable(_odooOrders);
  List<Map<String, dynamic>> get syncedOrders => List.unmodifiable(_syncedOrders);
  DateTime? get lastPosSyncedAt => _lastPosSyncedAt;
  DateTime? get lastOrdersSyncedAt => _lastOrdersSyncedAt;
  OutletInfo? get activeOutlet => _activeOutlet;

  // Date Filter Getters
  DateFilterPreset get dateFilterPreset => _dateFilterPreset;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String get dateFilterLabel => _dateFilterLabel;

  static String _formatDateShort(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  void _applyPresetDates(DateFilterPreset preset, {DateTimeRange? customRange}) {
    final now = DateTime.now();
    _dateFilterPreset = preset;
    switch (preset) {
      case DateFilterPreset.today:
        _filterStartDate = DateTime(now.year, now.month, now.day);
        _filterEndDate = DateTime(now.year, now.month, now.day);
        _dateFilterLabel = _formatDateShort(now);
        break;
      case DateFilterPreset.yesterday:
        final y = now.subtract(const Duration(days: 1));
        _filterStartDate = DateTime(y.year, y.month, y.day);
        _filterEndDate = DateTime(y.year, y.month, y.day);
        _dateFilterLabel = _formatDateShort(y);
        break;
      case DateFilterPreset.last7Days:
        final s = now.subtract(const Duration(days: 6));
        _filterStartDate = DateTime(s.year, s.month, s.day);
        _filterEndDate = DateTime(now.year, now.month, now.day);
        _dateFilterLabel = 'Last 7 Days';
        break;
      case DateFilterPreset.thisMonth:
        _filterStartDate = DateTime(now.year, now.month, 1);
        _filterEndDate = DateTime(now.year, now.month + 1, 0);
        _dateFilterLabel = 'This Month';
        break;
      case DateFilterPreset.custom:
        if (customRange != null) {
          _filterStartDate = DateTime(
              customRange.start.year, customRange.start.month, customRange.start.day);
          _filterEndDate = DateTime(
              customRange.end.year, customRange.end.month, customRange.end.day);
          if (_filterStartDate == _filterEndDate) {
            _dateFilterLabel = _formatDateShort(_filterStartDate!);
          } else {
            _dateFilterLabel =
                '${_formatDateShort(_filterStartDate!)} - ${_formatDateShort(_filterEndDate!)}';
          }
        }
        break;
      case DateFilterPreset.all:
        _filterStartDate = null;
        _filterEndDate = null;
        _dateFilterLabel = 'All Time';
        break;
    }
  }

  /// Sets active date filter preset and notifies listeners
  void setDateFilterPreset(DateFilterPreset preset, {DateTimeRange? customRange}) {
    _applyPresetDates(preset, customRange: customRange);
    notifyListeners();
  }

  /// Sets custom date range and notifies listeners
  void setCustomDateRange(DateTime start, DateTime end) {
    setDateFilterPreset(DateFilterPreset.custom,
        customRange: DateTimeRange(start: start, end: end));
  }

  /// Clears date filter (shows all orders)
  void clearDateFilter() {
    setDateFilterPreset(DateFilterPreset.all);
  }

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

  /// Checks whether an order falls within the active date filter range
  bool matchesDate(OdooOrder order) {
    if (_filterStartDate == null && _filterEndDate == null) return true;
    final orderDate = order.parsedDate;
    if (orderDate == null) return false;
    if (_filterStartDate != null && orderDate.isBefore(_filterStartDate!)) {
      return false;
    }
    if (_filterEndDate != null && orderDate.isAfter(_filterEndDate!)) {
      return false;
    }
    return true;
  }

  /// Returns filtered orders for active outlet
  List<OdooOrder> get filteredOrders => getOrdersForOutlet(_activeOutlet);

  /// Returns sorted orders for a given outlet (and optional channel 'Dine In' / 'Pick Up' / 'Delivery')
  List<OdooOrder> getOrdersForOutlet(OutletInfo? outlet, {String? channel}) {
    var list = _odooOrders
        .where((o) => matchesOutlet(o, outlet) && matchesDate(o))
        .toList();
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



  /// Fetches orders from Odoo via GET /api/list/orders
  Future<bool> fetchOrders({bool forceRefresh = false}) async {
    if (_isFromLiveApi && !forceRefresh) {
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final db = AuthService().currentUser?.db ?? 'ziplaban';
    final sessId = AuthService().currentUser?.sessionId;

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Odoo-Database': db,
        if (sessId != null && sessId.isNotEmpty) ...{
          'X-Openerp-Session-Id': sessId,
          'Cookie': 'session_id=$sessId',
        },
      };

      final response = await ApiClient.client
          .get(
            Uri.parse(listEndpoint),
            headers: headers,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('error') && data['error'] != null) {
          final err = data['error'];
          final errMsg = err is Map
              ? (err['data']?['message'] ?? err['message'])?.toString() ?? 'Odoo Server Error'
              : err.toString();

          if (errMsg.toLowerCase().contains('session expired')) {
            _isSessionExpired = true;
            _errorMessage = 'Odoo session expired. Please sign out and sign in again.';
            AuthService().markSessionExpired();
          } else {
            _errorMessage = errMsg;
          }
          if (_odooOrders.isNotEmpty) {
            _isUsingCachedData = true;
          }
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
          _isUsingCachedData = false;
          _isSessionExpired = false;
          _lastOrdersSyncedAt = DateTime.now();
          _lastPosSyncedAt = DateTime.now();
          _errorMessage = null;
          _saveOrdersToCache();
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Invalid response format from orders endpoint';
          if (_odooOrders.isNotEmpty) {
            _isUsingCachedData = true;
          }
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else if (response.statusCode == 404) {
        _errorMessage = 'Orders endpoint not found (404) for database "$db".';
        if (_odooOrders.isNotEmpty) {
          _isUsingCachedData = true;
        }
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        _errorMessage = 'Server error (${response.statusCode})';
        if (_odooOrders.isNotEmpty) {
          _isUsingCachedData = true;
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('xmlhttprequest') || errStr.contains('clientexception') || errStr.contains('failed to fetch')) {
        _errorMessage = 'Network connection issue or cross-origin access restricted.';
      } else if (errStr.contains('timeout')) {
        _errorMessage = 'Connection timeout: server took too long to respond.';
      } else {
        _errorMessage = 'Network error: ${e.toString()}';
      }
      if (_odooOrders.isNotEmpty) {
        _isUsingCachedData = true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
