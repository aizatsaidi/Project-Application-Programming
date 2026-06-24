import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2/activity_app/api';

  // ─── Activities ───────────────────────────────────────────────

  static Future<List<Activity>> getActivities() async {
    final response = await http.get(Uri.parse('$baseUrl/get_activities.php'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      if (decoded['success'] == true) {
        final List<dynamic> data = decoded['data'];
        return data.map((item) => Activity.fromJson(item)).toList();
      } else {
        throw Exception(decoded['message'] ?? 'Failed to load activities');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  static Future<void> addActivity({
    required String title,
    required String description,
    required String location,
    required String activityDate,
    required int capacity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_activity.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'location': location,
        'activity_date': activityDate,
        'capacity': capacity,
      }),
    );
    final decoded = jsonDecode(response.body);
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to add activity');
    }
  }

  static Future<void> updateActivity({
    required int activityId,
    required String title,
    required String description,
    required String location,
    required String activityDate,
    required int capacity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_activity.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'activity_id': activityId,
        'title': title,
        'description': description,
        'location': location,
        'activity_date': activityDate,
        'capacity': capacity,
      }),
    );
    final decoded = jsonDecode(response.body);
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to update activity');
    }
  }

  static Future<void> deleteActivity(int activityId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_activity.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'activity_id': activityId}),
    );
    final decoded = jsonDecode(response.body);
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to delete activity');
    }
  }

  // ─── Auth ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    String adminCode = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'admin_code': adminCode,
      }),
    );
    final Map<String, dynamic> decoded = jsonDecode(response.body);
    if (decoded['success'] == true) {
      return decoded['data'];
    } else {
      throw Exception(decoded['message'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final Map<String, dynamic> decoded = jsonDecode(response.body);
    if (decoded['success'] == true) {
      return decoded['data'];
    } else {
      throw Exception(decoded['message'] ?? 'Login failed');
    }
  }

  // ─── Registrations ────────────────────────────────────────────

  static Future<void> registerForActivity({
    required int userId,
    required int activityId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register_activity.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'activity_id': activityId}),
    );
    final Map<String, dynamic> decoded = jsonDecode(response.body);
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to register');
    }
  }

  static Future<List<Map<String, dynamic>>> getMyRegistrations(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_my_registrations.php?user_id=$userId'),
    );
    final Map<String, dynamic> decoded = jsonDecode(response.body);
    if (decoded['success'] == true) {
      return List<Map<String, dynamic>>.from(decoded['data']);
    } else {
      throw Exception(decoded['message'] ?? 'Failed to load registrations');
    }
  }

  static Future<void> cancelRegistration(int registrationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cancel_registration.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'registration_id': registrationId}),
    );
    final Map<String, dynamic> decoded = jsonDecode(response.body);
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to cancel registration');
    }
  }
}