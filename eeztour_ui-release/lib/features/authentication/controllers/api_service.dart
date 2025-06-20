// services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../../../common/config.dart';



class ApiService {
  static Future<http.Response> get(
      String endpoint, {
        BuildContext? context,
        Map<String, String>? additionalHeaders,
      }) async {
    final headers = await _getHeaders(context, additionalHeaders);

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    return _handleResponse(response, context);
  }

  static Future<http.Response> post(
      String endpoint, {
        Map<String, dynamic>? body,
        BuildContext? context,
        Map<String, String>? additionalHeaders,
      }) async {
    final headers = await _getHeaders(context, additionalHeaders);

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response, context);
  }

  static Future<http.Response> put(
      String endpoint, {
        Map<String, dynamic>? body,
        BuildContext? context,
        Map<String, String>? additionalHeaders,
      }) async {
    final headers = await _getHeaders(context, additionalHeaders);

    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response, context);
  }

  static Future<http.Response> delete(
      String endpoint, {
        BuildContext? context,
        Map<String, String>? additionalHeaders,
      }) async {
    final headers = await _getHeaders(context, additionalHeaders);

    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    return _handleResponse(response, context);
  }

  // Private method to get headers with authorization
  static Future<Map<String, String>> _getHeaders(
      BuildContext? context,
      Map<String, String>? additionalHeaders,
      ) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    // If context is provided, try to get auth headers from UserProvider
    if (context != null) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isAuthenticated) {
          headers['Authorization'] = '${userProvider.tokenType} ${userProvider.accessToken}';
        }
      } catch (e) {
        print('Could not get user provider: $e');
      }
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // Handle response and check for authentication errors
  static http.Response _handleResponse(http.Response response, BuildContext? context) {
    // If unauthorized and context is available, handle logout
    if (response.statusCode == 401 && context != null) {
      _handleUnauthorized(context);
    }

    return response;
  }

  // Handle unauthorized access
  static void _handleUnauthorized(BuildContext context) {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.clearUser();

      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('Error handling unauthorized access: $e');
    }
  }

  // Convenience method for API calls that return JSON
  static Future<Map<String, dynamic>> getJson(
      String endpoint, {
        BuildContext? context,
        Map<String, String>? additionalHeaders,
      }) async {
    final response = await get(endpoint, context: context, additionalHeaders: additionalHeaders);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> postJson(
      String endpoint, {
        Map<String, dynamic>? body,
        BuildContext? context,
        Map<String, String>? additionalHeaders,
      }) async {
    final response = await post(endpoint, body: body, context: context, additionalHeaders: additionalHeaders);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> putJson(
      String endpoint, {
        Map<String, dynamic>? body,
        BuildContext? context,
        Map<String, String>? additionalHeaders,
      }) async {
    final response = await put(endpoint, body: body, context: context, additionalHeaders: additionalHeaders);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteJson(
      String endpoint, {
        BuildContext? context,
        Map<String, String>? additionalHeaders,
      }) async {
    final response = await delete(endpoint, context: context, additionalHeaders: additionalHeaders);
    return jsonDecode(response.body);
  }
}