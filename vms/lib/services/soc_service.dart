import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/models/soc_profile.dart';

class SOCService extends ChangeNotifier {
  SOCProfile? _currentProfile;
  SOCProfile? get currentProfile => _currentProfile;

  Future<SOCProfile?> registerSOC({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    String? companyName,
    required String roleType,
    String? serviceCategory,
    String? bluetoothId,
    String? deviceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socRegister}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'phone_number': phoneNumber,
          'company_name': companyName,
          'role_type': roleType,
          'service_category': serviceCategory,
          'bluetooth_id': bluetoothId,
          'device_id': deviceId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _currentProfile = SOCProfile.fromJson(data);
        notifyListeners();
        return _currentProfile;
      }
      return null;
    } catch (e) {
      debugPrint('SOC Registration error: $e');
      return null;
    }
  }

  Future<SOCProfile?> lookupSOC(String socId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socLookup}/$socId'),
      );

      if (response.statusCode == 200) {
        return SOCProfile.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('SOC Lookup error: $e');
      return null;
    }
  }

  Future<SOCProfile?> detectSOC(String bluetoothId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.socDetect}/$bluetoothId',
        ),
      );

      if (response.statusCode == 200) {
        return SOCProfile.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('SOC Detect error: $e');
      return null;
    }
  }
}
