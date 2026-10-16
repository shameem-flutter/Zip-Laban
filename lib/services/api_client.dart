import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'http_client_factory.dart';

/// Centralized API client instance providing credentials and cookies for PWA
class ApiClient {
  ApiClient._();

  static final http.Client client = createHttpClient();

  /// Builds standardized headers for Odoo API requests across Web and Native.
  /// On Web, cookies are managed automatically by the browser withCredentials=true,
  /// avoiding browser 'Refused to set unsafe header "Cookie"' errors.
  /// On Mobile/Native, the Cookie header is passed explicitly.
  static Map<String, String> buildHeaders({
    String? db,
    String? sessionId,
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (db != null && db.isNotEmpty) 'X-Odoo-Database': db,
    };

    if (sessionId != null && sessionId.isNotEmpty) {
      headers['X-Openerp-Session-Id'] = sessionId;
      if (!kIsWeb) {
        headers['Cookie'] = 'session_id=$sessionId';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }
}
