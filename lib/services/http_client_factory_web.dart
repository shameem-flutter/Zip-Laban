import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Web implementation enabling browser cross-origin credential/cookie sharing
http.Client createHttpClient() {
  final client = BrowserClient()..withCredentials = true;
  return client;
}
