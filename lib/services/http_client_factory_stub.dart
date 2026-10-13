import 'package:http/http.dart' as http;

/// Non-web fallback (VM / flutter_test / Desktop / Mobile)
http.Client createHttpClient() => http.Client();
