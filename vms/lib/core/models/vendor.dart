class Vendor {
  final int id;
  final int userId;
  final String? phoneNumber;
  final String? companyName;
  final String? officeAddress;
  final String verificationStatus;
  final String? vendorUid;
  final String? dob;
  final String? gender;
  final String? website;
  final String? gstin;
  final String? description;
  final String? logoUrl;
  final String? email;
  final String? fullName;

  Vendor({
    required this.id,
    required this.userId,
    this.phoneNumber,
    this.companyName,
    this.officeAddress,
    required this.verificationStatus,
    this.vendorUid,
    this.dob,
    this.gender,
    this.website,
    this.gstin,
    this.description,
    this.logoUrl,
    this.email,
    this.fullName,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    // Handle verification_status - ensure it's a string
    String verificationStatus = 'PENDING';
    if (json['verification_status'] != null) {
      final status = json['verification_status'];
      if (status is String) {
        verificationStatus = status;
      } else {
        // If it's an enum or object, convert to string
        verificationStatus = status.toString().toUpperCase();
        // Remove enum prefix if present (e.g., "VerificationStatus.VERIFIED" -> "VERIFIED")
        if (verificationStatus.contains('.')) {
          verificationStatus = verificationStatus.split('.').last;
        }
      }
    }
    
    return Vendor(
      id: json['id'],
      userId: json['user_id'],
      phoneNumber: json['phone_number'],
      companyName: json['company_name'],
      officeAddress: json['office_address'],
      verificationStatus: verificationStatus,
      vendorUid: json['vendor_uid'],
      dob: json['dob'],
      gender: json['gender'],
      website: json['website'],
      gstin: json['gstin'],
      description: json['description'],
      logoUrl: json['logo_url'],
      email: json['email'],
      fullName: json['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'phone_number': phoneNumber,
      'company_name': companyName,
      'office_address': officeAddress,
      'verification_status': verificationStatus,
      'vendor_uid': vendorUid,
      'dob': dob,
      'gender': gender,
      'website': website,
      'gstin': gstin,
      'description': description,
      'logo_url': logoUrl,
      'email': email,
      'full_name': fullName,
    };
  }
}
