class Activity {
  final int activityId;
  final String title;
  final String description;
  final String location;
  final String activityDate;
  final int capacity;
  final String status; // 'upcoming' or 'completed'

  Activity({
    required this.activityId,
    required this.title,
    required this.description,
    required this.location,
    required this.activityDate,
    required this.capacity,
    this.status = 'upcoming',
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      activityId: json['activity_id'] != null
          ? (json['activity_id'] is int
              ? json['activity_id']
              : int.tryParse(json['activity_id'].toString()) ?? 0)
          : 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      activityDate: (json['activity_date'] ?? '').toString(),
      capacity: json['capacity'] != null
          ? (json['capacity'] is int
              ? json['capacity']
              : int.tryParse(json['capacity'].toString()) ?? 0)
          : 0,
      status: (json['status'] ?? 'upcoming').toString(),
    );
  }
}