import 'package:http/http.dart' as http;

class AppHttpClient {
  AppHttpClient._();

  static final http.Client _client = http.Client();

  static http.Client get shared => _client;

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _client.get(url, headers: headers).timeout(timeout);
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _client.post(url, headers: headers, body: body).timeout(timeout);
  }

  static Future<http.StreamedResponse> send(
    http.BaseRequest request, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _client.send(request).timeout(timeout);
  }

  static Future<http.Response> download(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 300),
  }) async {
    return _client.get(url, headers: headers).timeout(timeout);
  }

  static void dispose() {
    _client.close();
  }
}
