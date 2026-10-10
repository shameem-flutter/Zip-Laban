import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../models/sales_model.dart';

class UserSession {
  final int uid;
  final String name;
  final String username;
  final String db;
  final String serverVersion;
  final List<OutletInfo> branches;
  final String? sessionId;

  const UserSession({
    required this.uid,
    required this.name,
    required this.username,
    required this.db,
    required this.serverVersion,
    required this.branches,
    this.sessionId,
  });

  factory UserSession.fromOdooResult(Map<String, dynamic> result, {String? sessionId}) {
    final uid = result['uid'] as int? ?? 0;
    final name = result['name'] as String? ?? 'Admin';
    final username = result['username'] as String? ?? 'admin';
    final db = result['db'] as String? ?? '';
    final serverVersion = result['server_version'] as String? ?? '19.0';

    final List<OutletInfo> branchesList = [];

    // Parse allowed companies / branches from user_companies
    final userCompanies = result['user_companies'] as Map<String, dynamic>?;
    if (userCompanies != null && userCompanies['allowed_companies'] is Map) {
      final allowed = userCompanies['allowed_companies'] as Map<String, dynamic>;
      allowed.forEach((key, val) {
        if (val is Map) {
          final id = val['id']?.toString() ?? key;
          final rawName = val['name'] as String? ?? 'Branch $key';
          final companyName = rawName.trim();
          String short = companyName;
          if (short.length > 18) {
            short = '${short.substring(0, 15)}...';
          }
          branchesList.add(
            OutletInfo(
              id: id,
              name: companyName,
              shortName: short,
              location: companyName.contains('KOTTAKKAL')
                  ? 'Kottakkal, Malappuram'
                  : (companyName.contains('KADAMPUZHA')
                      ? 'Kadampuzha, Kerala'
                      : 'Branch Location'),
              posTerminalId: 'POS-0$id',
            ),
          );
        }
      });
    }

    if (branchesList.isEmpty) {
      final fallbackName = name.isNotEmpty ? '$name Branch' : 'Main Branch';
      branchesList.add(
        OutletInfo(
          id: '1',
          name: fallbackName,
          shortName: fallbackName,
          location: 'Main Location',
          posTerminalId: 'POS-01',
        ),
      );
    }

    return UserSession(
      uid: uid,
      name: name,
      username: username,
      db: db,
      serverVersion: serverVersion,
      branches: branchesList,
      sessionId: sessionId,
    );
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserSession? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserSession? get currentUser => _currentUser;
  bool get isAuthenticated => currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const String endpoint = ApiEndpoints.authenticate;



  Future<bool> login({
    required String db,
    required String login,
    required String password,
  }) async {
    final trimmedDb = db.trim();
    final trimmedLogin = login.trim();
    final trimmedPass = password.trim();

    if (trimmedDb.isEmpty) {
      _errorMessage = 'Please enter database name.';
      notifyListeners();
      return false;
    }
    if (trimmedLogin.isEmpty) {
      _errorMessage = 'Please enter username or email.';
      notifyListeners();
      return false;
    }
    if (trimmedPass.isEmpty) {
      _errorMessage = 'Please enter your password.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'jsonrpc': '2.0',
        'params': {
          'db': trimmedDb,
          'login': trimmedLogin,
          'password': trimmedPass,
        },
      };

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('error')) {
          final err = data['error'] as Map<String, dynamic>;
          final errData = err['data'] as Map<String, dynamic>?;
          final errorName = errData?['name']?.toString() ?? '';
          final errorMsg = errData?['message']?.toString() ?? err['message']?.toString() ?? '';

          if (errorName.contains('AccessDenied') ||
              errorMsg.toLowerCase().contains('access denied')) {
            _errorMessage = 'Invalid username or password. Please verify your credentials.';
          } else if (errorMsg.toLowerCase().contains('database') &&
              errorMsg.toLowerCase().contains('not')) {
            _errorMessage = "Database '$trimmedDb' does not exist on server.";
          } else if (errorMsg.isNotEmpty && errorMsg != 'Odoo Server Error') {
            _errorMessage = errorMsg;
          } else {
            _errorMessage = 'Authentication failed. Please verify your credentials.';
          }
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final result = data['result'] as Map<String, dynamic>?;
        if (result != null && result['uid'] != null && result['uid'] != false) {
          String? sessId;
          final rawCookie = response.headers['set-cookie'];
          if (rawCookie != null && rawCookie.contains('session_id=')) {
            final match = RegExp(r'session_id=([^;]+)').firstMatch(rawCookie);
            sessId = match?.group(1);
          }

          _currentUser = UserSession.fromOdooResult(result, sessionId: sessId);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Invalid username or password for database "$trimmedDb".';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Server error (${response.statusCode}): Failed to authenticate.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('xmlhttprequest') || errStr.contains('clientexception')) {
        _errorMessage = 'CORS error: The browser blocked this cross-origin request. Please enable CORS on the Odoo server.';
      } else if (errStr.contains('timeout')) {
        _errorMessage = 'Connection timed out. The server took too long to respond.';
      } else if (errStr.contains('socketexception') || errStr.contains('failed host lookup')) {
        _errorMessage = 'Unable to reach the server. Please check your network connection.';
      } else {
        _errorMessage = 'Authentication failed: ${e.toString()}';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
