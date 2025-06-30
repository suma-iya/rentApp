class AppNotification {
  final int id;
  final String message;
  final String status;
  final String createdAt;
  final NotificationProperty property;
  final NotificationFloor floor;
  final bool showActions;
  final bool isRead;
  final String? comment;

  AppNotification({
    required this.id,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.property,
    required this.floor,
    required this.showActions,
    required this.isRead,
    this.comment,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      message: json['message'],
      status: json['status'],
      createdAt: json['created_at'],
      property: NotificationProperty.fromJson(json['property']),
      floor: NotificationFloor.fromJson(json['floor']),
      showActions: json['show_actions'] ?? false,
      isRead: json['is_read'] ?? false,
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'status': status,
      'created_at': createdAt,
      'property': property.toJson(),
      'floor': floor.toJson(),
      'show_actions': showActions,
      'is_read': isRead,
      'comment': comment,
    };
  }
}

class NotificationProperty {
  final int id;
  final String name;

  NotificationProperty({
    required this.id,
    required this.name,
  });

  factory NotificationProperty.fromJson(Map<String, dynamic> json) {
    return NotificationProperty(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class NotificationFloor {
  final int id;
  final String name;

  NotificationFloor({
    required this.id,
    required this.name,
  });

  factory NotificationFloor.fromJson(Map<String, dynamic> json) {
    return NotificationFloor(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
} 