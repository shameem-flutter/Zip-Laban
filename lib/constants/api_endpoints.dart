/// Centralized Odoo API Endpoints & Server Configuration
class ApiEndpoints {
  ApiEndpoints._();

  /// Primary Server Domain & Base URL
  static const String baseDomain = 'ziplaban.odoo.waslasoft.com';
  static const String baseUrl = 'https://$baseDomain';

  /// Authentication & Session
  /// POST /web/session/authenticate
  static const String authenticate = '$baseUrl/web/session/authenticate';

  /// Product Catalog
  /// POST /api/get_products_data
  static const String getProductsData = '$baseUrl/api/get_products_data';

  // Disabled write API (Pure Analytics App):
  // POST /api/create_product
  // static const String createProduct = '$baseUrl/api/create_product';

  /// Customers & CRM
  /// POST /api/get_contact_data (POST query returning list of contacts)
  static const String getContactData = '$baseUrl/api/get_contact_data';

  // Disabled write API (Pure Analytics App):
  // POST /api/create_customer
  // static const String createCustomer = '$baseUrl/api/create_customer';

  /// Companies & Branches (POST returning list of company data)
  /// POST /api/get_company_data
  static const String getCompanyData = '$baseUrl/api/get_company_data';

  // Disabled write API (Pure Analytics App):
  // POST /api/create/sale_order
  // static const String createSaleOrder = '$baseUrl/api/create/sale_order';

  /// List Invoiced Orders across all branches (Analytics)
  /// GET /api/list/orders
  static const String listOrders = '$baseUrl/api/list/orders';

  /// Salespersons & Staff (POST query returning list of salespersons)
  /// POST /api/get_salesperson_data
  static const String getSalespersonData = '$baseUrl/api/get_salesperson_data';
}

