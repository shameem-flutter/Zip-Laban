import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../models/odoo_salesperson.dart';
import 'auth_service.dart';

/// Service for managing salespersons and waitstaff via Odoo JSON-RPC API
/// Endpoint: POST /api/get_salesperson_data (POST request returning query data)
class SalespersonService extends ChangeNotifier {
  static final SalespersonService _instance = SalespersonService._internal();
  factory SalespersonService() => _instance;
  SalespersonService._internal() {
    _populateDefaultSalespersons();
  }

  static const String endpoint = ApiEndpoints.getSalespersonData;

  List<OdooSalesperson> _salespersons = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastSyncedAt;
  bool _isFromLiveApi = false;

  List<OdooSalesperson> get salespersons => List.unmodifiable(_salespersons);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isFromLiveApi => _isFromLiveApi;

  // Exact dataset from user's Odoo /api/get_salesperson_data response
  static final List<Map<String, dynamic>> defaultSalespersonResult = [
    {
      "id": 5,
      "name": "ADMIN",
      "company_id": 1,
      "company_name": "ZIP LABAN",
    },
    {
      "id": 2,
      "name": "Administrator",
      "company_id": 1,
      "company_name": "ZIP LABAN",
    },
  ];

  void _populateDefaultSalespersons() {
    _salespersons = defaultSalespersonResult
        .map((json) => OdooSalesperson.fromJson(json))
        .toList();
    _lastSyncedAt = DateTime.now();
  }

  /// Fetches salespersons from the Odoo endpoint
  /// POST /api/get_salesperson_data
  Future<bool> fetchSalespersons({bool forceRefresh = false}) async {
    if (_salespersons.isNotEmpty && !forceRefresh) {
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
            Uri.parse(endpoint),
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
              'Failed to retrieve salesperson data';
          _errorMessage = msg.toString();
          if (_salespersons.isEmpty) {
            _populateDefaultSalespersons();
          }
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final result = data['result'];
        if (result is List) {
          _salespersons = result
              .whereType<Map<String, dynamic>>()
              .map((item) => OdooSalesperson.fromJson(item))
              .toList();
          _isFromLiveApi = true;
          _lastSyncedAt = DateTime.now();
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Invalid response format from salesperson endpoint';
          if (_salespersons.isEmpty) {
            _populateDefaultSalespersons();
          }
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Server error (${response.statusCode})';
        if (_salespersons.isEmpty) {
          _populateDefaultSalespersons();
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network connection error: ${e.toString()}';
      if (_salespersons.isEmpty) {
        _populateDefaultSalespersons();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
