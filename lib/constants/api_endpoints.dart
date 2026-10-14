/// Centralized Odoo API Endpoints & Server Configuration
class ApiEndpoints {
  ApiEndpoints._();

  /// Primary Server Domain & Base URL
  static const String baseDomain = 'ziplaban.waslasoft.com';
  static const String baseUrl = 'https://$baseDomain';

  /// Authentication & Session
  /// POST /web/session/authenticate
  static const String authenticate = '$baseUrl/web/session/authenticate';

  /// Companies & Branches (POST returning list of company data)
  /// POST /api/get_company_data
  static const String getCompanyData = '$baseUrl/api/get_company_data';

  /// List Invoiced Orders across all branches (Analytics)
  /// GET /api/list/orders
  static const String listOrders = '$baseUrl/api/list/orders';
}
