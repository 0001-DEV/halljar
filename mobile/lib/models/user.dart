class User {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String role; // 'BUYER' or 'SELLER'
  final String estateId;
  final String unit;

  User({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.estateId,
    this.unit = '',
  });

  bool get isSeller => role == 'SELLER';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'BUYER',
      estateId: json['estateId'] ?? 'est_citiview',
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'estateId': estateId,
      'unit': unit,
    };
  }
}
