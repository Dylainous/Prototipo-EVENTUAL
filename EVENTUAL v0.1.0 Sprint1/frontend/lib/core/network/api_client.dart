// lib/core/network/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final http.Client _client;

  ApiClient(this._client);

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String url) async {
    final headers = await _buildHeaders();
    return _client.get(Uri.parse(url), headers: headers);
  }

  Future<http.Response> post(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    return _client.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String url, Map<String, dynamic> body) async {
    final headers = await _buildHeaders();
    return _client.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> patch(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _buildHeaders();
    return _client.patch(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
