import 'package:http/http.dart' as http;
import 'http_client_factory.dart';

/// Centralized API client instance providing credentials and cookies for PWA
class ApiClient {
  ApiClient._();

  static final http.Client client = createHttpClient();
}
