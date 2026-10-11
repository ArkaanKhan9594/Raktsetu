import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;
  final String? baseUrl;
  String? authToken;

  ApiClient({http.Client? client, this.baseUrl}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Uri _uri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final effectiveBase = baseUrl ?? AppConfig.apiBaseUrl;
    final base = effectiveBase.endsWith('/')
        ? effectiveBase.substring(0, effectiveBase.length - 1)
        : effectiveBase;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$base$path').replace(queryParameters: queryParams);
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _client
          .get(_uri(endpoint, queryParams), headers: _headers)
          .timeout(AppConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network and try again.');
    } on TimeoutException {
      throw ApiException('Connection timed out. The server is taking too long to respond.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: $e');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    try {
      final response = await _client
          .post(
            _uri(endpoint),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network and try again.');
    } on TimeoutException {
      throw ApiException('Connection timed out. The server is taking too long to respond.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: $e');
    }
  }

  Future<dynamic> patch(String endpoint, {dynamic body}) async {
    try {
      final response = await _client
          .patch(
            _uri(endpoint),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network and try again.');
    } on TimeoutException {
      throw ApiException('Connection timed out. The server is taking too long to respond.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _client
          .delete(_uri(endpoint), headers: _headers)
          .timeout(AppConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network and try again.');
    } on TimeoutException {
      throw ApiException('Connection timed out. The server is taking too long to respond.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    String message = 'Server returned status ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        message = decoded['error'].toString();
      }
    } catch (_) {}

    throw ApiException(message, statusCode: response.statusCode);
  }
}
