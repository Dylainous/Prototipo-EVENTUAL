// lib/core/network/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient(this._client, {this.baseUrl = 'http://localhost:3000/api'});

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

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw Exception(body['error'] ?? 'Error ${response.statusCode}');
  }

  Future<Map<String, dynamic>> get(String path) async {
    final headers = await _buildHeaders();
    final response = await _client.get(Uri.parse('$baseUrl$path'), headers: headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool requiresAuth = true}) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final response = await _client.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final headers = await _buildHeaders();
    final response = await _client.put(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    final headers = await _buildHeaders();
    final response = await _client.patch(Uri.parse('$baseUrl$path'), headers: headers, body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final headers = await _buildHeaders();
    final response = await _client.delete(Uri.parse('$baseUrl$path'), headers: headers);
    return _handleResponse(response);
  }
}
