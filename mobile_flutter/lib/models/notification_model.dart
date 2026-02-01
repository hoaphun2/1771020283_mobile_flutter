class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime time;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.time,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    message: json['message'] ?? '',
    type: json['type'] ?? 'info',
    time: json['time'] != null ? DateTime.tryParse(json['time']) ?? DateTime.now() : DateTime.now(),
    isRead: json['isRead'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'time': time.toIso8601String(),
    'isRead': isRead,
  };
}
