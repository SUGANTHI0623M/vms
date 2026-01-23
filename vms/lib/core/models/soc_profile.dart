class SOCProfile {
  final int id;
  final int userId;
  final String socId;
  final String phoneNumber;
  final String? companyName;
  final String roleType;
  final String? photoUrl;
  final String? govIdUrl;
  final String? serviceCategory;
  final String? bluetoothId;
  final String? deviceId;
  final bool isVerified;
  final DateTime createdAt;

  SOCProfile({
    required this.id,
    required this.userId,
    required this.socId,
    required this.phoneNumber,
    this.companyName,
    required this.roleType,
    this.photoUrl,
    this.govIdUrl,
    this.serviceCategory,
    this.bluetoothId,
    this.deviceId,
    required this.isVerified,
    required this.createdAt,
  });

  factory SOCProfile.fromJson(Map<String, dynamic> json) {
    return SOCProfile(
      id: json['id'],
      userId: json['user_id'],
      socId: json['soc_id'],
      phoneNumber: json['phone_number'],
      companyName: json['company_name'],
      roleType: json['role_type'],
      photoUrl: json['photo_url'],
      govIdUrl: json['gov_id_url'],
      serviceCategory: json['service_category'],
      bluetoothId: json['bluetooth_id'],
      deviceId: json['device_id'],
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'soc_id': socId,
      'phone_number': phoneNumber,
      'company_name': companyName,
      'role_type': roleType,
      'photo_url': photoUrl,
      'gov_id_url': govIdUrl,
      'service_category': serviceCategory,
      'bluetooth_id': bluetoothId,
      'device_id': deviceId,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
