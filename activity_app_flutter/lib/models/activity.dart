class Activity {
  final int activityId;
  final String title;
  final String description;
  final String location;
  final String activityDate;
  final int capacity;

  Activity({
    required this.activityId,
    required this.title,
    required this.description,
    required this.location,
    required this.activityDate,
    required this.capacity,
  });

  // Converts the JSON we get from PHP into an Activity object
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      activityId: json['activity_id'] is int
          ? json['activity_id']
          : int.parse(json['activity_id'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      activityDate: json['activity_date'] ?? '',
      capacity: json['capacity'] is int
          ? json['capacity']
          : int.parse(json['capacity'].toString()),
    );
  }
}