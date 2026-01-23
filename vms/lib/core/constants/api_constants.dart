class ApiConstants {
  //static const String baseUrl = 'https://vms-bgqc.onrender.com/api/v1';
  static const String baseUrl = 'http://10.78.114.36:8000/api/v1';

  static const String login = '/auth/login';

  // Legacy aliases (mapped to new SOC system where possible)
  static const String vendorMe = '/vendors/me';
  static const String checkIn =
      '/visits/check-in'; // Note: This endpoint might need to be re-implemented or handled differently

  // SOC Profile
  static const String socRegister = '/profiles/register';
  static const String socMe = '/profiles/me';
  static const String socLookup = '/profiles/lookup'; // + /{soc_id}
  static const String socDetect = '/profiles/detect'; // + /{bluetooth_id}

  // Visits
  static const String visitRequest = '/visits/request';
  static const String visitStatusUpdate = '/visits'; // + /{visit_id}/status
  static const String visitCheckIn = '/visits'; // + /{visit_id}/check-in
  static const String visitCheckOut = '/visits'; // + /{visit_id}/check-out
  static const String pendingVisits = '/visits/pending';

  static const String uploadDoc = '/documents/upload';
}
