import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../models/odoo_customer.dart';
import 'auth_service.dart';

/// Service for querying contacts and creating customers in Odoo
/// Endpoints:
/// - POST /api/get_contact_data (POST request returning contacts query data)
/// - POST /api/create_customer (POST request to create new customer)
class CustomerService extends ChangeNotifier {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal() {
    _initDefaultCustomers();
  }

  // Disabled (Analytics Only):
  // static const String endpoint = ApiEndpoints.createCustomer;
  static const String getContactEndpoint = ApiEndpoints.getContactData;

  final List<OdooCustomer> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  DateTime? _lastSyncedAt;
  bool _isFromLiveApi = false;

  List<OdooCustomer> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isFromLiveApi => _isFromLiveApi;

  List<OdooCustomer> get filteredCustomers {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _customers;
    return _customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.mobile.toLowerCase().contains(q) ||
          c.customerId.toLowerCase().contains(q) ||
          c.city.toLowerCase().contains(q) ||
          (c.companyName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Exact dataset from user's Odoo /api/get_contact_data response
  static final List<Map<String, dynamic>> defaultContactsResult = [
    {
      "customer_id": 6,
      "name": "ADMIN",
      "phone": false,
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": false,
      "company": false,
      "email": false,
      "address": [false, false, false]
    },
    {
      "customer_id": 3,
      "name": "Administrator",
      "phone": false,
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": 1,
      "company": "ZIP LABAN",
      "email": false,
      "address": [false, false, false]
    },
    {
      "customer_id": 10,
      "name": "Default Customer (Kadampuzha)",
      "phone": false,
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": 3,
      "company": "KADAMPUZHA BRANCH",
      "email": false,
      "address": [false, false, false]
    },
    {
      "customer_id": 9,
      "name": "Default Customer (Kottakkal)",
      "phone": false,
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": 2,
      "company": "KOTTAKKAL BRANCH",
      "email": false,
      "address": [false, false, false]
    },
    {
      "customer_id": 8,
      "name": "KADAMPUZHA BRANCH",
      "phone": false,
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": false,
      "company": false,
      "email": false,
      "address": ["Kadampuzha, Malappuram", false, "India"]
    },
    {
      "customer_id": 7,
      "name": "KOTTAKKAL BRANCH",
      "phone": "7510129229",
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": false,
      "company": false,
      "email": false,
      "address": ["Palathara, Malappuram", false, "India"]
    },
    {
      "customer_id": 12,
      "name": "Test Customer 1",
      "phone": "0000000000",
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": 1,
      "company": "ZIP LABAN",
      "email": false,
      "address": ["Street 1", "City", "India"]
    },
    {
      "customer_id": 14,
      "name": "Test Customer 2",
      "phone": "0000000000",
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": 1,
      "company": "ZIP LABAN",
      "email": false,
      "address": ["Street 1", "City", "India"]
    },
    {
      "customer_id": 13,
      "name": "Test Customer 2",
      "phone": "0000000000",
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": 1,
      "company": "ZIP LABAN",
      "email": false,
      "address": ["Street 1", "City", "India"]
    },
    {
      "customer_id": 17,
      "name": "Waslasoft Test Customer 2",
      "phone": "9876543210",
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": 1,
      "company": "ZIP LABAN",
      "email": false,
      "address": ["Street 1", "Calicut", "India"]
    },
    {
      "customer_id": 16,
      "name": "Waslasoft Test Customer 2",
      "phone": "9876543210",
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": 1,
      "company": "ZIP LABAN",
      "email": false,
      "address": ["Street 1", "Calicut", "India"]
    },
    {
      "customer_id": 1,
      "name": "ZIP LABAN",
      "phone": "",
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": false,
      "company": false,
      "email": false,
      "address": ["PALATHARA", "Malappuram", "India"]
    }
  ];

  void _initDefaultCustomers() {
    if (_customers.isNotEmpty) return;
    _populateDefaultCustomers();
  }

  void _populateDefaultCustomers() {
    _customers.clear();
    _customers.addAll(
      defaultContactsResult.map((c) => OdooCustomer.fromJson(c)).toList(),
    );
    _lastSyncedAt = DateTime.now();
  }

  /// Fetches contacts/customers from Odoo via POST /api/get_contact_data
  Future<bool> fetchCustomers({bool forceRefresh = false}) async {
    if (_customers.isNotEmpty && !forceRefresh) {
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

      final response = await http
          .post(
            Uri.parse(getContactEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (sessId != null && sessId.isNotEmpty) 'Cookie': 'session_id=$sessId',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('error') && data['error'] != null) {
          final err = data['error'] as Map<String, dynamic>;
          final msg = err['message'] ??
              err['data']?['message'] ??
              'Failed to retrieve contacts';
          _errorMessage = msg.toString();
          if (_customers.isEmpty) {
            _populateDefaultCustomers();
          }
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final result = data['result'];
        if (result is List) {
          _customers.clear();
          _customers.addAll(
            result
                .whereType<Map<String, dynamic>>()
                .map((item) => OdooCustomer.fromJson(item)),
          );
          _isFromLiveApi = true;
          _lastSyncedAt = DateTime.now();
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Invalid response format from contacts endpoint';
          if (_customers.isEmpty) {
            _populateDefaultCustomers();
          }
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Server error (${response.statusCode})';
        if (_customers.isEmpty) {
          _populateDefaultCustomers();
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network connection error: ${e.toString()}';
      if (_customers.isEmpty) {
        _populateDefaultCustomers();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Disabled: Customer creation is not used in this Analytics-only Dashboard
  Future<CreateCustomerResult> createCustomer(CreateCustomerInput input) async {
    // Disabled (Analytics Only):
    // POST /api/create_customer is removed
    return const CreateCustomerResult(
      success: false,
      msg: 'Customer creation is disabled. This app is dedicated to analytics and reporting.',
    );
  }
}
