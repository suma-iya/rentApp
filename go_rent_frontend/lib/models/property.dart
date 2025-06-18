class Property {
  final int id;
  final String name;
  final String address;
  final String createdAt;

  Property({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'created_at': createdAt,
    };
  }
} 