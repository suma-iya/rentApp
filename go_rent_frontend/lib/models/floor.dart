class Floor {
  final int id;
  final String name;
  final int rent;
  final String createdAt;
  final int? tenant;
  final String? status;
  final int? notificationId;

  Floor({
    required this.id,
    required this.name,
    required this.rent,
    required this.createdAt,
    this.tenant,
    this.status,
    this.notificationId,
  });

  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['id'],
      name: json['name'],
      rent: json['rent'],
      createdAt: json['created_at'],
      tenant: json['tenant'],
      status: json['status'],
      notificationId: json['notification_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rent': rent,
      'created_at': createdAt,
      'tenant': tenant,
      'status': status,
      'notification_id': notificationId,
    };
  }
} 