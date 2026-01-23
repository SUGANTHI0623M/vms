enum VisitStatus { PENDING, APPROVED, REJECTED, WAITING, COMPLETED, EXITED }

class Visit {
  final int id;
  final int socProfileId;
  final int organizationId;
  final int securityId;
  final int? hostId;
  final String department;
  final String purpose;
  final VisitStatus status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? serviceStatus;
  final int? rating;
  final String? feedback;
  final String? checkInSelfieUrl;

  Visit({
    required this.id,
    required this.socProfileId,
    required this.organizationId,
    required this.securityId,
    this.hostId,
    required this.department,
    required this.purpose,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.checkInTime,
    this.checkOutTime,
    this.serviceStatus,
    this.rating,
    this.feedback,
    this.checkInSelfieUrl,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'],
      socProfileId: json['soc_profile_id'],
      organizationId: json['organization_id'],
      securityId: json['security_id'],
      hostId: json['host_id'],
      department: json['department'],
      purpose: json['purpose'],
      status: VisitStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => VisitStatus.PENDING,
      ),
      requestedAt: DateTime.parse(json['requested_at']),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      serviceStatus: json['service_status'],
      rating: json['rating'],
      feedback: json['feedback'],
      checkInSelfieUrl: json['check_in_selfie_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'soc_profile_id': socProfileId,
      'organization_id': organizationId,
      'security_id': securityId,
      'host_id': hostId,
      'department': department,
      'purpose': purpose,
      'status': status.toString().split('.').last,
      'requested_at': requestedAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'service_status': serviceStatus,
      'rating': rating,
      'feedback': feedback,
      'check_in_selfie_url': checkInSelfieUrl,
    };
  }
}
