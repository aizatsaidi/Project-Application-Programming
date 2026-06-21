import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';

class ApiService {
  // 10.0.2.2 is the special alias the Android Emulator uses
  // to reach "localhost" on your actual PC.
  static const String baseUrl = 'http://10.0.2.2/activity_app/api';

  // Fetches the list of all activities from get_activities.php
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
}