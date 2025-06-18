import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property.dart';
import '../models/floor.dart';
import '../models/notification.dart' as models;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'http://192.168.0.230:8080';
  String? _sessionToken;
  final _client = http.Client();

  Future<void> setSessionToken(String token) async {
    _sessionToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', token);
    print('Session token set: $_sessionToken');
  }

  Future<void> loadSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionToken = prefs.getString('session_token');
    print('Loaded session token: $_sessionToken');
  }

  Future<void> clearSessionToken() async {
    _sessionToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    print('Session token cleared');
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_sessionToken != null) {
      headers['Cookie'] = 'sessiontoken=$_sessionToken';
      print('Adding session token to headers: $_sessionToken');
    }
    
    return headers;
  }

  // LOGIN
  Future<bool> login(String phoneNumber, String password) async {
    try {
      print('Attempting login with phone: $phoneNumber');
      final response = await _client.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );
      
      print('Login response status: ${response.statusCode}');
      print('Login response headers: ${response.headers}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        // Extract session cookie
        final setCookie = response.headers['set-cookie'];
        print('Set-Cookie header: $setCookie');
        
        if (setCookie != null) {
          final sessionMatch = RegExp(r'sessiontoken=([^;]+)').firstMatch(setCookie);
          if (sessionMatch != null) {
            await setSessionToken(sessionMatch.group(1)!);
            return true;
          }
        }
        print('No session token found in response');
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login error: $e');
    }
  }

  // REGISTRATION
  Future<bool> register(String phoneNumber, String password, {required String name}) async {
    try {
      print('Attempting registration with phone: $phoneNumber');
      final response = await _client.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
          'name': name,
          'password': password,
        }),
      );
      
      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');
      
      return response.statusCode == 201;
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration error: $e');
    }
  }

  Future<List<Property>> getProperties() async {
    try {
      print('Fetching properties with headers: $_headers');
      final response = await _client.get(
        Uri.parse('$baseUrl/properties'),
        headers: _headers,
      );

      print('Properties response status: ${response.statusCode}');
      print('Properties response headers: ${response.headers}');
      print('Properties response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> propertiesJson = data['properties'];
          return propertiesJson.map((json) => Property.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load properties');
        }
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching properties: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<List<Property>> getTenantProperties() async {
    try {
      print('Fetching tenant properties with headers: $_headers');
      final response = await _client.get(
        Uri.parse('$baseUrl/property/tenant'),
        headers: _headers,
      );

      print('Tenant properties response status: ${response.statusCode}');
      print('Tenant properties response headers: ${response.headers}');
      print('Tenant properties response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic>? propertiesJson = data['properties'];
          return propertiesJson?.map((json) => Property.fromJson(json)).toList() ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to load tenant properties');
        }
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tenant properties: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<Property> getPropertyById(int id) async {
    try {
      print('Fetching property from: $baseUrl/property/$id');
      final response = await _client.get(
        Uri.parse('$baseUrl/property/$id'),
        headers: _headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          return Property.fromJson(data['property']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load property');
        }
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching property: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<bool> addProperty(String name, String address) async {
    try {
      print('Adding property to: $baseUrl/property');
      print('Adding session token to headers: $_sessionToken');

      final response = await _client.post(
        Uri.parse('$baseUrl/property'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'address': address,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] ?? false;
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding property: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getPropertyDetails(int id) async {
    try {
      print('Fetching property details from: $baseUrl/property/$id');
      final response = await _client.get(
        Uri.parse('$baseUrl/property/$id'),
        headers: _headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          final property = Property.fromJson(data['property']);
          final List<dynamic> floorsJson = data['floors'] ?? [];
          final floors = floorsJson.map((json) {
            // Check if there's a pending notification for this floor
            if (json['status'] == 'pending' && json['notification'] != null) {
              json['notification_id'] = json['notification']['id'];
              json['status'] = 'pending';
            }
            return Floor.fromJson(json);
          }).toList();
          return {
            'property': property,
            'floors': floors,
            'is_manager': data['is_manager'] ?? false,
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to load property details');
        }
      } else if (response.statusCode == 401) {
        await clearSessionToken(); // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching property details: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<bool> addFloor(int propertyId, String name, int rent) async {
    try {
      print('Adding floor to property: $propertyId');
      final response = await _client.post(
        Uri.parse('$baseUrl/property/$propertyId/floor'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'rent': rent,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'];
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding floor: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<bool> addTenantToFloor(int propertyId, int floorId, String tenantName, String phoneNumber) async {
    try {
      print('Adding tenant to floor: $floorId in property: $propertyId');
      final response = await _client.post(
        Uri.parse('$baseUrl/property/$propertyId/floor/$floorId/tenant'),
        headers: _headers,
        body: json.encode({
          'name': tenantName,
          'phone_number': phoneNumber,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'];
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding tenant: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<bool> removeTenantFromFloor(int propertyId, int floorId) async {
    try {
      print('Removing tenant from floor: $floorId in property: $propertyId');
      final response = await _client.delete(
        Uri.parse('$baseUrl/property/$propertyId/floor/$floorId/tenant'),
        headers: _headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] ?? false;
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing tenant: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<bool> updateFloor(int propertyId, int floorId, String name, int rent) async {
    try {
      print('Updating floor: $floorId in property: $propertyId');
      final response = await _client.put(
        Uri.parse('$baseUrl/property/$propertyId/floor/$floorId'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'rent': rent,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'];
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating floor: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<int> getUserIdByPhone(String phoneNumber) async {
    try {
      print('Getting user ID for phone: $phoneNumber');
      final response = await _client.get(
        Uri.parse('$baseUrl/users/phones/$phoneNumber'),
        headers: _headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          return data['user_id'];
        } else {
          throw Exception(data['message'] ?? 'Failed to get user ID');
        }
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting user ID: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<bool> sendTenantRequest(int propertyId, int floorId, String phoneNumber) async {
    try {
      print('Sending tenant request for property: $propertyId, floor: $floorId');
      final response = await _client.post(
       Uri.parse('$baseUrl/property/$propertyId/floor/$floorId/request'),
        headers: _headers,
        body: json.encode({
          'phone_number': phoneNumber,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] ?? false;
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 409) {
        final Map<String, dynamic> data = json.decode(response.body);
        throw Exception(data['message'] ?? 'A pending request already exists for this floor');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending tenant request: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<List<String>> getUserPhones() async {
    try {
      print('Fetching user phones');
      final response = await _client.get(
        Uri.parse('$baseUrl/users/phones'),
        headers: _headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> users = data['users'];
          return users.map((user) => user['phone_number'] as String).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load user phones');
        }
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user phones: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<bool> sendNotification(int userId, String message) async {
    try {
      print('Sending notification to user: $userId');
      final response = await _client.post(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers,
        body: json.encode({
          'user_id': userId,
          'message': message,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'];
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending notification: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      print('Deleting notification: $notificationId');
      final response = await _client.delete(
        Uri.parse('$baseUrl/notifications/delete/$notificationId'),
        headers: _headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] ?? false;
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting notification: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<List<models.AppNotification>> getNotifications() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          // Handle null notifications by returning an empty list
          final notifications = data['notifications'] as List<dynamic>?;
          if (notifications == null) {
            return [];
          }
          return notifications.map((n) => models.AppNotification.fromJson(n)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load notifications');
        }
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<bool> handleTenantRequestAction(int notificationId, bool accept) async {
    try {
      print('Handling tenant request action for notification: $notificationId');
      final response = await _client.post(
        Uri.parse('$baseUrl/notifications/action'),
        headers: _headers,
        body: json.encode({
          'notification_id': notificationId,
          'accept': accept,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] ?? false;
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error handling tenant request action: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<List<Property>> getUserProperties() async {
    try {
      print('Fetching user properties with headers: $_headers');
      final response = await _client.get(
        Uri.parse('$baseUrl/properties'),
        headers: _headers,
      );

      print('User properties response status: ${response.statusCode}');
      print('User properties response headers: ${response.headers}');
      print('User properties response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> propertiesJson = data['properties'];
          return propertiesJson.map((json) => Property.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load properties');
        }
      } else if (response.statusCode == 401) {
        _sessionToken = null; // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user properties: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  Future<List<Property>> getUserTenantProperties() async {
    try {
      print('Fetching tenant properties with headers: $_headers');
      final response = await _client.get(
        Uri.parse('$baseUrl/properties/tenant'),
        headers: _headers,
      );

      print('Tenant properties response status: ${response.statusCode}');
      print('Tenant properties response headers: ${response.headers}');
      print('Tenant properties response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> propertiesJson = data['properties'] ?? [];
          final properties = propertiesJson.map((json) => Property.fromJson(json)).toList();
          print('Parsed ${properties.length} tenant properties');
          return properties;
        } else {
          throw Exception(data['message'] ?? 'Failed to load tenant properties');
        }
      } else if (response.statusCode == 401) {
        await clearSessionToken(); // Clear invalid session token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tenant properties: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to server. Please check if the server is running and you have internet connection.');
      }
      throw Exception('Error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
} 