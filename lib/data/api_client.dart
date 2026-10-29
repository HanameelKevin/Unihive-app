import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Thin JSON HTTP client for Supabase REST, Auth, and Edge Function APIs.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Set from the authenticated Supabase session for protected requests.
  String? authToken = AppConfig.authTokenOrNull;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        ...query.map((k, v) => MapEntry(k, '$v')),
      },
    );
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AppConfig.supabaseAnonKey.isNotEmpty)
          'apikey': AppConfig.supabaseAnonKey,
        if (authToken != null || AppConfig.supabaseAnonKey.isNotEmpty)
          'Authorization':
              'Bearer ' + (authToken ?? AppConfig.supabaseAnonKey),
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _client.get(_uri(path, query), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await _client.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    final dynamic data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (!ok) {
      final msg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Request failed (HTTP ${res.statusCode})';
      final code = data is Map ? data['code']?.toString() : null;
      throw ApiException(msg, res.statusCode, code: code);
    }
    return data;
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode, {this.code});
  final String message;
  final int statusCode;
  final String? code;
  @override
  String toString() => message;
}
