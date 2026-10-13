import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';
import '../models/odoo_company.dart';
import '../models/sales_model.dart';
import 'auth_service.dart';

/// Service for managing companies & store branches via Odoo JSON-RPC API
/// Endpoint: POST /api/get_company_data (POST request returning query data)
class CompanyService extends ChangeNotifier {
  static final CompanyService _instance = CompanyService._internal();
  factory CompanyService() => _instance;
  CompanyService._internal();

  static const String endpoint = ApiEndpoints.getCompanyData;
  static const String _cachedCompaniesKey = 'waslasoft_cached_companies';

  List<OdooCompany> _companies = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastSyncedAt;
  bool _isFromLiveApi = false;

  List<OdooCompany> get companies => _companies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isFromLiveApi => _isFromLiveApi;

  /// Returns [OutletInfo] list converted from active Odoo companies
  List<OutletInfo> get outlets =>
      _companies.map((c) => c.toOutletInfo()).toList();

  /// Restores cached companies from persistent storage on startup
  Future<void> restoreCachedCompanies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cachedCompaniesKey);
      if (jsonStr != null && jsonStr.isNotEmpty && _companies.isEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        _companies = list
            .whereType<Map<String, dynamic>>()
            .map((item) => OdooCompany.fromJson(item))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring cached companies: $e');
    }
  }

  Future<void> _saveCompaniesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _companies.map((c) => c.toJson()).toList();
      await prefs.setString(_cachedCompaniesKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving cached companies: $e');
    }
  }

  void clear() {
    _companies = [];
    _isLoading = false;
    _errorMessage = null;
    _lastSyncedAt = null;
    _isFromLiveApi = false;
    notifyListeners();
  }

  /// Fetches branch and company data from the Odoo endpoint
  /// POST /api/get_company_data
  Future<bool> fetchCompanies({bool forceRefresh = false}) async {
    if (_isFromLiveApi && !forceRefresh) {
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final db = AuthService().currentUser?.db ?? 'ziplaban';
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
              'X-Odoo-Database': db,
              if (sessId != null && sessId.isNotEmpty) ...{
                'X-Openerp-Session-Id': sessId,
                'Cookie': 'session_id=$sessId',
              },
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('error')) {
          final err = data['error'] as Map<String, dynamic>;
          final msg = err['message'] ??
              err['data']?['message'] ??
              'Failed to retrieve company data';
          _errorMessage = msg.toString();
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final result = data['result'];
        if (result is List) {
          _companies = result
              .whereType<Map<String, dynamic>>()
              .map((item) => OdooCompany.fromJson(item))
              .toList();
          _isFromLiveApi = true;
          _lastSyncedAt = DateTime.now();
          _saveCompaniesToCache();
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Invalid response format from company endpoint';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Server responded with status code: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network connection error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
